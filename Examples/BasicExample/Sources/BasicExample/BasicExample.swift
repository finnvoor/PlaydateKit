import PlaydateKit

final class BasicExample: PlaydateGame {
    init() {
        Playdate.System.addMenuItem(title: "PlaydateKit") { _ in
            Playdate.System.logToConsole(format: "PlaydateKit selected!")
        }
    }

    func update() -> Bool {
        Playdate.System.drawFPS()
        return true
    }

    func gameWillPause() {
        Playdate.System.logToConsole(format: "Paused!")
    }
}
