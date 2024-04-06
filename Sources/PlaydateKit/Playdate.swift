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
        arc4random_seed = System.millisecondsSinceEpoch
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

nonisolated(unsafe) var arc4random_seed: CUnsignedInt = 0
@_documentation(visibility: internal)
@_cdecl("arc4random") public func arc4random() -> UInt32 {
    arc4random_seed = 1664525 &* arc4random_seed &+ 1013904223
    return arc4random_seed
}

/// Implement `arc4random_buf` which is required by the Embedded Swift runtime for Hashable, Set, Dictionary,
/// and random-number generating APIs but is not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("arc4random_buf") public func arc4random_buf(buf: UnsafeMutableRawPointer, nbytes: Int) {
    var r = arc4random()
    for i in 0..<nbytes {
        if i % 4 == 0 {
            r = arc4random()
        }
        buf.advanced(by: i).assumingMemoryBound(to: UInt8.self).pointee = UInt8(r & 0xff)
        r >>= 8
    }
}
