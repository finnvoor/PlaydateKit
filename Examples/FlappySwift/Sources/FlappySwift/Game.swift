import PlaydateKit

// MARK: - TestScene

final class TestScene: Scene {}

// MARK: - Game

@PlaydateMain
final class Game: PlaydateGame {
    var highScore = 0

    var scene: Scene = {
        let scene = SplashScreen()
        scene.onLoad()
        return scene
    }() {
        didSet {
            oldValue.onUnload()
            scene.onLoad()
        }
    }

    func update() -> Bool {
        Sprite.updateAndDrawDisplayListSprites()
        return true
    }
}
