@preconcurrency public import CPlaydate

// MARK: - Playdate

public enum Playdate {
    public struct Error: Swift.Error, @unchecked Sendable {
        let humanReadableText: UnsafePointer<CChar>?
    }

    public static var playdateAPI: PlaydateAPI { playdate.pointee }

    public static func initialize(with pointer: UnsafeMutableRawPointer) {
        playdate = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1)
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
