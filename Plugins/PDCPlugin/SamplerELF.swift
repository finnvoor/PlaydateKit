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
        var rewritten = 0
        var units = 0
        var edits: [(range: Range<Int>, bytes: [UInt8])] = []
        forEachLineUnit { _, unitEnd, unit in
            units += 1
            guard let encoded = unit.encodeFillingLineZero(), encoded.count <= unitEnd - unit.programStart else { return }
            // DW_LNS_set_basic_block is a one-byte opcode with no effect on the rows addr2line reads.
            let padding = [UInt8](repeating: 0x07, count: unitEnd - unit.programStart - encoded.count)
            edits.append((unit.programStart..<unitEnd, encoded + padding))
            rewritten += 1
        }
        for edit in edits {
            bytes.replaceSubrange(edit.range, with: edit.bytes)
        }
        return (rewritten, units)
    }

    /// Code with no line rows at all (newlib, libgcc, merged and outlined Swift functions) has no
    /// location either. One extra compile unit gives each such function a row in a `nodebug` file, on
    /// a line of its own; addr2line then names it from the symbol table.
    mutating func addLinesForUncoveredFunctions() -> Int {
        guard let symtabIndex = sections[".symtab"], let lineIndex = sections[".debug_line"],
              let infoIndex = sections[".debug_info"], let abbrevIndex = sections[".debug_abbrev"],
              let rangesIndex = sections[".debug_ranges"]
        else { return 0 }

        var covered: [Range<Int>] = []
        forEachLineUnit { _, _, unit in covered += unit.addressRanges }
        covered.sort { $0.lowerBound < $1.lowerBound }
        let symtab = headers[symtabIndex]
        var functions: [Int: Int] = [:]
        for index in 0..<symtab.size / 16 {
            let entry = symtab.offset + index * 16
            let size = Int(u32(entry + 8))
            // STT_FUNC; the low bit of a Thumb function's value is not part of its address.
            guard bytes[entry + 12] & 0xF == 2, size > 0 else { continue }
            functions[Int(u32(entry + 4)) & ~1, default: 0] = max(functions[Int(u32(entry + 4)) & ~1] ?? 0, size)
        }
        let uncovered = functions.map { $0.key..<$0.key + $0.value }.sorted { $0.lowerBound < $1.lowerBound }.filter { function in
            var low = 0, high = covered.count
            while low < high {
                let middle = (low + high) / 2
                if covered[middle].lowerBound < function.upperBound {
                    low = middle + 1
                } else {
                    high = middle
                }
            }
            return low == 0 || covered[low - 1].upperBound <= function.lowerBound
        }
        guard !uncovered.isEmpty else { return 0 }

        let file = Array("nodebug".utf8) + [0]
        // DWARF 2 line header: minimum_instruction_length 1, default_is_stmt 1, line_base -5,
        // line_range 14, opcode_base 13, no include directories, one file.
        var lineHeader: [UInt8] = [1, 1, 0xFB, 14, 13, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0]
        lineHeader += file + [0, 0, 0, 0]
        var lineProgram: [UInt8] = []
        var ranges: [UInt8] = []
        for (index, function) in uncovered.enumerated() {
            lineProgram += [0, 5, 2] + littleEndian32(function.lowerBound) + [3] + sleb(index) + [1]
            lineProgram += [2] + uleb(function.count) + [0, 1, 1]
            ranges += littleEndian32(function.lowerBound) + littleEndian32(function.upperBound)
        }
        let lineUnit = [2, 0] + littleEndian32(lineHeader.count) + lineHeader + lineProgram
        let lineOffset = append(littleEndian32(lineUnit.count) + lineUnit, to: lineIndex)
        let rangesOffset = append(ranges + [UInt8](repeating: 0, count: 8), to: rangesIndex)
        // compile_unit, no children: name string, stmt_list sec_offset, low_pc addr, ranges sec_offset.
        let abbrevOffset = append([1, 0x11, 0, 0x03, 0x08, 0x10, 0x17, 0x11, 0x01, 0x55, 0x17, 0, 0, 0], to: abbrevIndex)
        let unit = [4, 0] + littleEndian32(abbrevOffset) + [4, 1] + file + littleEndian32(lineOffset)
            + littleEndian32(0) + littleEndian32(rangesOffset)
        _ = append(littleEndian32(unit.count) + unit, to: infoIndex)
        return uncovered.count
    }

    func write() throws {
        try Data(bytes).write(to: url)
    }

    // MARK: Private

    private struct Section {
        /// File offset of this section's header.
        let header: Int
        let name: Int
        var offset: Int
        var size: Int
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

    private func forEachLineUnit(_ body: (_ start: Int, _ end: Int, LineProgram) -> Void) {
        guard let section = sections[".debug_line"].map({ headers[$0] }) else { return }
        var position = section.offset
        let end = section.offset + section.size
        while position + 10 <= end {
            let unitEnd = position + 4 + Int(u32(position))
            if let unit = LineProgram(bytes: bytes, at: position, end: unitEnd) {
                body(position, unitEnd, unit)
            }
            position = unitEnd
        }
    }

    /// Moves a section to the end of the file with `extra` after its contents, and returns where
    /// `extra` starts within the section. Only for sections not loaded on device.
    private mutating func append(_ extra: [UInt8], to index: Int) -> Int {
        let section = headers[index]
        let contents = Array(bytes[section.offset..<section.offset + section.size]) + extra
        headers[index].offset = bytes.count
        headers[index].size = contents.count
        setU32(section.header + 16, bytes.count)
        setU32(section.header + 20, contents.count)
        bytes += contents
        return section.size
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

    var addressRanges: [Range<Int>] {
        sequences.compactMap { sequence in sequence.rows.first.map { $0.address..<sequence.end } }
    }

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
                // Special opcodes and DW_LNS_advance_pc can't move back in address.
                guard addressAdvance >= 0 else { return nil }
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
            guard sequence.end >= address else { return nil }
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
}

// MARK: - Encoding

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
