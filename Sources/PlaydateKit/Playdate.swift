@_documentation(visibility: internal)
@_exported
import CPlaydate

// MARK: - Playdate

public enum Playdate {
    // MARK: Public

    /// An error thrown from the Playdate C API.
    public struct Error: Swift.Error, CustomStringConvertible, @unchecked Sendable {
        // MARK: Lifecycle

        package init(description: String) {
            self.description = description
        }

        // MARK: Public

        public let description: String
    }

    /// Access to the Playdate C API.
    public static var playdateAPI: PlaydateAPI! {
        guard let _playdateAPI else {
            fatalError("playdateAPI is not set! Did you forget to call Playdate.initialize(with:)?")
        }
        return _playdateAPI
    }

    public static func initialize(with pointer: UnsafeMutablePointer<PlaydateAPI>) {
        _playdateAPI = pointer.pointee
        pd_srand(System.millisecondsSinceEpoch)
        System.setUpdateCallback(update: { _ in
            (System.updateCallback?() ?? false) ? 1 : 0
        }, userdata: nil)
    }

    // MARK: Private

    private nonisolated(unsafe) static var _playdateAPI: PlaydateAPI?
}

/// Implement `arc4random_buf` which is required by the Embedded Swift runtime for Hashable, Set, Dictionary,
/// and random-number generating APIs but is not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("arc4random_buf") public func arc4random_buf(buf: UnsafeMutableRawPointer, nbytes: Int) {
    for i in stride(from: 0, to: nbytes - 1, by: 2) {
        let randomValue = UInt16(pd_rand() & Int32(UInt16.max))
        (buf + i).assumingMemoryBound(to: UInt16.self).pointee = randomValue
    }
    if nbytes % 2 == 1 {
        let randomValue = UInt8(pd_rand() & Int32(UInt8.max))
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
