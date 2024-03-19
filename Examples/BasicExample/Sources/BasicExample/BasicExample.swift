import PlaydateKit

final class BasicExample: PlaydateGame {
    // MARK: Lifecycle

    init() {
        System.addMenuItem(title: "PlaydateKit") { _ in
            System.log("PlaydateKit selected!")
        }
    }

    // MARK: Internal

    func update() -> Bool {
        System.drawFPS()
        return true
    }

    func gameWillPause() {
        System.log("Paused!")
    }
}
