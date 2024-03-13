@preconcurrency public import CPlaydate

public enum Playdate {
    public static func initialize(with pointer: UnsafeMutableRawPointer) {
        playdate = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1)
    }
}

/// Implement `posix_memalign(3)`, which is required by the Swift runtime but is
/// not provided by the Playdate C library.
@_documentation(visibility: internal)
@_cdecl("posix_memalign")
public func posix_memalign(
    _ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
    _ alignment: Int,
    _ size: Int
) -> CInt {
    guard let allocation = malloc(Int(size + alignment - 1)) else {
#if hasFeature(Embedded)
        fatalError()
#else
        fatalError("Unable to handle memory request: Out of memory.")
#endif
    }
    let misalignment = Int(bitPattern: allocation) % alignment
#if hasFeature(Embedded)
    precondition(misalignment == 0)
#else
    precondition(
        misalignment == 0,
        "Unable to handle requests for over-aligned memory.")
#endif
    memptr.pointee = allocation
    return 0
}
