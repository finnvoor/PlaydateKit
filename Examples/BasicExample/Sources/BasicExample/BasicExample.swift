public import CPlaydate
import PlaydateKit

@_cdecl("update") func update(_: UnsafeMutableRawPointer!) -> Int32 { 1 }

@_cdecl("eventHandler") public func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: PDSystemEvent,
    _: UInt32
) -> Int32 {
    let playdate = pointer.bindMemory(to: PlaydateAPI.self, capacity: 1)
    if event == .initialize {
        Playdate.initialize(with: playdate)
        Playdate.System.setUpdateCallback(update: update, userdata: nil)

        _ = Playdate.System.addMenuItem(title: "PlaydateKit") { _ in
            Playdate.System.logToConsole(format: "PlaydateKit selected!")
        }
    }
    return 0
}
