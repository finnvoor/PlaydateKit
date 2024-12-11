@_documentation(visibility: internal)
@_exported
public import CPlaydate

@attached(member, names: named(shared))
@attached(peer, names: named(_eventHandler))
public macro PlaydateMain() = #externalMacro(module: "PlaydateKitMacros", type: "PlaydateMainMacro")

// MARK: - Playdate

public enum Playdate {
    // MARK: Public

    /// An error thrown from the Playdate C API.
    public struct Error: Swift.Error, CustomStringConvertible, @unchecked Sendable {
        public let description: String
    }

    /// Access to the Playdate C API.
    public static var playdateAPI: PlaydateAPI! {
        guard let _playdateAPI else {
            fatalError("playdateAPI is not set! Did you forget to call Playdate.initialize(with:)?")
        }
        return _playdateAPI
    }

    public static func initialize(with pointer: UnsafeMutableRawPointer) {
        _playdateAPI = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1).pointee
        srand(System.millisecondsSinceEpoch)
        System.setUpdateCallback(update: { _ in
            (System.updateCallback?() ?? false) ? 1 : 0
        }, userdata: nil)
    }

    // MARK: Private

    private nonisolated(unsafe) static var _playdateAPI: PlaydateAPI?
}

/// Implement `posix_memalign(3)`, which is required by the Embedded Swift runtime but is
/// not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("posix_memalign") public func posix_memalign(
    _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
    _ alignment: Int,
    _ size: Int
) -> CInt {
    guard let allocation = malloc(Int(size + alignment - 1)) else { fatalError() }
    let misalignment = Int(bitPattern: allocation) % alignment
    precondition(misalignment == 0)
    memptr.pointee = allocation
    return 0
}

/// Implement `arc4random_buf` which is required by the Embedded Swift runtime for Hashable, Set, Dictionary,
/// and random-number generating APIs but is not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("arc4random_buf") public func arc4random_buf(buf: UnsafeMutableRawPointer, nbytes: Int) {
    for i in stride(from: 0, to: nbytes - 1, by: 2) {
        let randomValue = UInt16(rand() & Int32(UInt16.max))
        (buf + i).assumingMemoryBound(to: UInt16.self).pointee = randomValue
    }
    if nbytes % 2 == 1 {
        let randomValue = UInt8(rand() & Int32(UInt8.max))
        (buf + nbytes - 1).assumingMemoryBound(to: UInt8.self).pointee = randomValue
    }
}

@_documentation(visibility: internal) private nonisolated(unsafe) var buffer: [CChar] = []
/// Implement `putchar` which is required by the Embedded Swift runtime for `print` but is
/// not provided by the Playdate C library.
///
/// Due to https://devforum.play.date/t/logtoconsole-without-a-linebreak/1819,
/// printed characters are stored in a buffer and only logged to the Playdate console once a newline
/// is printed.
@_documentation(visibility: internal)
@_cdecl("putchar") public func putchar(char: CInt) -> CInt {
    if char == 0x0a {
        buffer.append(0)
        System.log(String(cString: &buffer))
        buffer = []
    } else {
        buffer.append(CChar(char))
    }
    return char
}
