@preconcurrency public import CPlaydate

// MARK: - Playdate

public enum Playdate {
    public struct Error: Swift.Error, @unchecked Sendable {
        let humanReadableText: UnsafePointer<CChar>?
    }

    nonisolated(unsafe) public static var playdateAPI: PlaydateAPI! {
        guard let _playdateAPI else {
            fatalError("playdateAPI is not set! Did you forget to call Playdate.initialize(with:)?")
        }
        return _playdateAPI
    }
    nonisolated(unsafe) private static var _playdateAPI: PlaydateAPI?

    public static func initialize(with pointer: UnsafeMutableRawPointer) {
        _playdateAPI = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1).pointee
    }
}

/// Implement `posix_memalign(3)`, which is required by the Swift runtime but is
/// not provided by the Playdate C library.
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
