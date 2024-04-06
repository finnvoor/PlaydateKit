@_documentation(visibility: internal)
@_exported
public import CPlaydate

// MARK: - Playdate

public enum Playdate {
    // MARK: Public

    /// An error thrown from the Playdate C API.
    public struct Error: Swift.Error, @unchecked Sendable {
        let humanReadableText: UnsafePointer<CChar>?
    }

    /// Access to the Playdate C API.
    public nonisolated(unsafe) static var playdateAPI: PlaydateAPI! {
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
    var i = 0
    while i <= nbytes - 4 {
        (buf + i).assumingMemoryBound(to: Int32.self).pointee = rand()
        i += 4
    }

    if nbytes - 1 > 0 {
        let rand = UInt32(rand())
        for j in 0..<(nbytes - i) {
            (buf + i + j).assumingMemoryBound(to: UInt8.self).pointee = UInt8(truncatingIfNeeded: rand >> (j * 8))
        }
    }
}
