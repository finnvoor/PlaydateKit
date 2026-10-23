import Foundation

// MARK: - SamplerELF

/// Rewrites the copy of `pdex.elf` published for the Simulator's Sampler, which symbolizes `Device - C`
/// samples with `arm-none-eabi-addr2line -f -p`: no `-C`, no `-i`. Only that copy is changed, never
/// the code that runs on device.
struct SamplerELF {
    // MARK: Lifecycle

    init(url: URL) throws {
        self.url = url
        bytes = try [UInt8](Data(contentsOf: url))
        guard bytes.count > 0x34, bytes[0..<4] == [0x7F, 0x45, 0x4C, 0x46], bytes[4] == 1, bytes[5] == 1 else {
            throw Error.notELF32LittleEndian
        }
        let sectionHeaders = Int(u32(0x20))
        let entrySize = Int(u16(0x2E))
        let count = Int(u16(0x30))
        let namesIndex = Int(u16(0x32))
        for index in 0..<count {
            let header = sectionHeaders + index * entrySize
            headers.append(Section(
                header: header,
                name: Int(u32(header)),
                offset: Int(u32(header + 16)),
                size: Int(u32(header + 20)),
                link: Int(u32(header + 24))
            ))
        }
        for (index, section) in headers.enumerated() {
            let name = String(decoding: cString(at: headers[namesIndex].offset + section.name), as: UTF8.self)
            sections[name] = index
        }
    }

    // MARK: Internal

    enum Error: Swift.Error {
        case notELF32LittleEndian
    }

    /// binutils swaps a DWARF function name for the ELF symbol starting at the same address so that
    /// `-C` can demangle C++. That gives mangled Swift names, so demangle the symbols themselves.
    mutating func demangleSymbols(demangler: URL) throws -> Int {
        guard let symtabIndex = sections[".symtab"], headers.indices.contains(headers[symtabIndex].link) else {
            return 0
        }
        let symtab = headers[symtabIndex]
        let strtab = headers[symtab.link]
        var mangled: [(offset: Int, name: [UInt8])] = []
        for offset in Set((0..<symtab.size / 16).map { Int(u32(symtab.offset + $0 * 16)) }).sorted() {
            let name = cString(at: strtab.offset + offset)
            if name.starts(with: "$e".utf8) || name.starts(with: "$s".utf8) {
                mangled.append((offset, name))
            }
        }
        guard !mangled.isEmpty else { return 0 }

        let input = mangled.map { String(decoding: $0.name, as: UTF8.self) }.joined(separator: "\n") + "\n"
        let demangled = try run(demangler, arguments: ["--simplified"], input: Data(input.utf8))
            .split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false)

        // Demangled names are often longer, so the string table moves to the end of the file with the
        // new names appended. It is not loaded on device, so nothing else refers to where it was.
        var table = Array(bytes[strtab.offset..<strtab.offset + strtab.size])
        var renamedOffsets: [Int: Int] = [:]
        for (symbol, readable) in zip(mangled, demangled) where !readable.isEmpty && Array(readable) != symbol.name {
            renamedOffsets[symbol.offset] = table.count
            table += readable + [0]
        }
        for index in 0..<symtab.size / 16 {
            let entry = symtab.offset + index * 16
            if let renamed = renamedOffsets[Int(u32(entry))] {
                setU32(entry, renamed)
            }
        }
        setU32(strtab.header + 16, bytes.count)
        setU32(strtab.header + 20, table.count)
        bytes += table
        return renamedOffsets.count
    }

    /// Swift and LLVM put line 0 on much inlined and compiler-generated code, which addr2line without
    /// `-i` reports as no location: the Sampler files all of it under one unknown entry. Rows on line 0
    /// take the line before them instead; a sequence that is all line 0 gets line 1. Every unit keeps
    /// its size, so nothing that points into `.debug_line` needs updating.
    mutating func fillLineZero() -> (rewritten: Int, units: Int) {
        guard let section = sections[".debug_line"].map({ headers[$0] }) else { return (0, 0) }
        var rewritten = 0
        var units = 0
        var position = section.offset
        let end = section.offset + section.size
        while position + 10 <= end {
            let unitEnd = position + 4 + Int(u32(position))
            defer { position = unitEnd }
            units += 1
            guard let unit = LineProgram(bytes: bytes, at: position, end: unitEnd),
                  let encoded = unit.encodeFillingLineZero(),
                  encoded.count <= unitEnd - unit.programStart
            else { continue }
            // DW_LNS_set_basic_block is a one-byte opcode with no effect on the rows addr2line reads.
            let padding = [UInt8](repeating: 0x07, count: unitEnd - unit.programStart - encoded.count)
            bytes.replaceSubrange(unit.programStart..<unitEnd, with: encoded + padding)
            rewritten += 1
        }
        return (rewritten, units)
    }

    func write() throws {
        try Data(bytes).write(to: url)
    }

    // MARK: Private

    private struct Section {
        /// File offset of this section's header.
        let header: Int
        let name: Int
        let offset: Int
        let size: Int
        let link: Int
    }

    private let url: URL
    private var bytes: [UInt8]
    private var headers: [Section] = []
    private var sections: [String: Int] = [:]

    private func u16(_ offset: Int) -> UInt16 {
        UInt16(bytes[offset]) | UInt16(bytes[offset + 1]) << 8
    }

    private func u32(_ offset: Int) -> UInt32 {
        UInt32(u16(offset)) | UInt32(u16(offset + 2)) << 16
    }

    private mutating func setU32(_ offset: Int, _ value: Int) {
        for byte in 0..<4 {
            bytes[offset + byte] = UInt8(truncatingIfNeeded: value >> (byte * 8))
        }
    }

    private func cString(at offset: Int) -> [UInt8] {
        Array(bytes[offset..<(bytes[offset...].firstIndex(of: 0) ?? bytes.endIndex)])
    }

    private func run(_ tool: URL, arguments: [String], input: Data) throws -> Data {
        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        let stdin = Pipe()
        let stdout = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        try process.run()
        // Write on another thread: a large input would otherwise fill both pipes and deadlock.
        let writer = Thread {
            stdin.fileHandleForWriting.write(input)
            try? stdin.fileHandleForWriting.close()
        }
        writer.start()
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw PDCPlugin.Error.unexpectedStatus(reason: process.terminationReason, status: process.terminationStatus)
        }
        return output
    }
}

// MARK: - LineProgram

/// One DWARF 2-4 `.debug_line` unit, decoded to the rows addr2line uses: address, file and line.
private struct LineProgram {
    // MARK: Lifecycle

    init?(bytes: [UInt8], at start: Int, end: Int) {
        func u16(_ offset: Int) -> Int {
            Int(bytes[offset]) | Int(bytes[offset + 1]) << 8
        }
        func u32(_ offset: Int) -> Int {
            u16(offset) | u16(offset + 2) << 16
        }

        let version = u16(start + 4)
        guard (2...4).contains(version) else { return nil }
        programStart = start + 10 + u32(start + 6)
        var cursor = start + 10
        minimumInstructionLength = Int(bytes[cursor])
        cursor += version >= 4 ? 3 : 2
        lineBase = Int(Int8(bitPattern: bytes[cursor]))
        lineRange = Int(bytes[cursor + 1])
        opcodeBase = Int(bytes[cursor + 2])
        let operandCounts = Array(bytes[cursor + 3..<cursor + 2 + opcodeBase])
        guard lineRange > 0, programStart <= end else { return nil }

        var reader = Reader(bytes: bytes, position: programStart)
        var rows: [Row] = []
        var address = 0, file = 1, line = 1
        while reader.position < end {
            let opcode = Int(reader.byte())
            if opcode >= opcodeBase {
                let adjusted = opcode - opcodeBase
                address += adjusted / lineRange * minimumInstructionLength
                line += lineBase + adjusted % lineRange
                rows.append(Row(address: address, file: file, line: line))
                continue
            }
            switch opcode {
            case 0:
                let length = reader.uleb()
                let next = reader.position + length
                let extended = reader.byte()
                if extended == 1 {
                    sequences.append(Sequence(rows: rows, end: address))
                    rows = []
                    address = 0; file = 1; line = 1
                } else if extended == 2 {
                    address = u32(reader.position)
                }
                reader.position = next
            case 1: rows.append(Row(address: address, file: file, line: line))
            case 2: address += reader.uleb() * minimumInstructionLength
            case 3: line += reader.sleb()
            case 4: file = reader.uleb()
            case 8: address += (255 - opcodeBase) / lineRange * minimumInstructionLength
            case 9:
                address += u16(reader.position)
                reader.position += 2
            default:
                for _ in 0..<Int(operandCounts[opcode - 1]) {
                    _ = reader.uleb()
                }
            }
        }
    }

    // MARK: Internal

    let programStart: Int

    func encodeFillingLineZero() -> [UInt8]? {
        var output: [UInt8] = []
        for sequence in sequences {
            guard let first = sequence.rows.first else { continue }
            var previous = sequence.rows.first { $0.line != 0 }.map { ($0.file, $0.line) } ?? (first.file, 1)
            var rows: [Row] = []
            for var row in sequence.rows {
                if row.line == 0 {
                    (row.file, row.line) = previous
                } else {
                    previous = (row.file, row.line)
                }
                if let last = rows.last, last.file == row.file, last.line == row.line {
                    continue
                }
                if rows.last?.address == row.address {
                    rows.removeLast()
                }
                rows.append(row)
            }

            output += [0, 5, 2] + littleEndian32(rows[0].address)
            var address = rows[0].address, file = 1, line = 1
            for row in rows {
                if row.file != file {
                    output += [4] + uleb(row.file)
                    file = row.file
                }
                let addressAdvance = (row.address - address) / minimumInstructionLength
                var lineAdvance = row.line - line
                if !(lineBase..<lineBase + lineRange).contains(lineAdvance) {
                    output += [3] + sleb(lineAdvance)
                    lineAdvance = 0
                }
                let special = lineAdvance - lineBase + lineRange * addressAdvance + opcodeBase
                if special <= 255 {
                    output.append(UInt8(special))
                } else {
                    output += [2] + uleb(addressAdvance)
                    output.append(UInt8(lineAdvance - lineBase + opcodeBase))
                }
                address = row.address
                line = row.line
            }
            output += [2] + uleb((sequence.end - address) / minimumInstructionLength) + [0, 1, 1]
        }
        return output
    }

    // MARK: Private

    private struct Row {
        var address: Int
        var file: Int
        var line: Int
    }

    private struct Sequence {
        let rows: [Row]
        let end: Int
    }

    private struct Reader {
        let bytes: [UInt8]
        var position: Int

        mutating func byte() -> UInt8 {
            defer { position += 1 }
            return bytes[position]
        }

        mutating func uleb() -> Int {
            var result = 0, shift = 0
            while true {
                let byte = byte()
                result |= Int(byte & 0x7F) << shift
                shift += 7
                if byte < 0x80 {
                    return result
                }
            }
        }

        mutating func sleb() -> Int {
            var result = 0, shift = 0
            while true {
                let byte = byte()
                result |= Int(byte & 0x7F) << shift
                shift += 7
                if byte < 0x80 {
                    return byte & 0x40 != 0 ? result - (1 << shift) : result
                }
            }
        }
    }

    private let minimumInstructionLength: Int
    private let lineBase: Int
    private let lineRange: Int
    private let opcodeBase: Int
    private var sequences: [Sequence] = []

    private func littleEndian32(_ value: Int) -> [UInt8] {
        (0..<4).map { UInt8(truncatingIfNeeded: value >> ($0 * 8)) }
    }

    private func uleb(_ value: Int) -> [UInt8] {
        var value = value
        var output: [UInt8] = []
        repeat {
            var byte = UInt8(value & 0x7F)
            value >>= 7
            if value != 0 {
                byte |= 0x80
            }
            output.append(byte)
        } while value != 0
        return output
    }

    private func sleb(_ value: Int) -> [UInt8] {
        var value = value
        var output: [UInt8] = []
        while true {
            let byte = UInt8(value & 0x7F)
            value >>= 7
            if (value == 0 && byte & 0x40 == 0) || (value == -1 && byte & 0x40 != 0) {
                output.append(byte)
                return output
            }
            output.append(byte | 0x80)
        }
    }
}
