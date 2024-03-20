public import CPlaydate

// MARK: - Playdate

public typealias Display = Playdate.Display
public typealias File = Playdate.File
public typealias Graphics = Playdate.Graphics
public typealias JSON = Playdate.JSON
// public typealias Lua = Playdate.Lua

public typealias Scoreboards = Playdate.Scoreboards
// public typealias Sound = Playdate.Sound

public typealias Sprite = Playdate.Sprite
public typealias System = Playdate.System

// MARK: - Playdate

public enum Playdate {
    // MARK: Public

    public struct Error: Swift.Error, @unchecked Sendable {
        let humanReadableText: UnsafePointer<CChar>?
    }

    public nonisolated(unsafe) static var playdateAPI: PlaydateAPI! {
        guard let _playdateAPI else {
            fatalError("playdateAPI is not set! Did you forget to call Playdate.initialize(with:)?")
        }
        return _playdateAPI
    }

    public static func initialize(with pointer: UnsafeMutableRawPointer) {
        _playdateAPI = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1).pointee
        System.setUpdateCallback(update: { _ in
            (System.updateCallback?() ?? false) ? 1 : 0
        }, userdata: nil)
    }

    // MARK: Private

    private nonisolated(unsafe) static var _playdateAPI: PlaydateAPI?
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
