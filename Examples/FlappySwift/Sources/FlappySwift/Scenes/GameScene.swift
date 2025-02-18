import PlaydateKit

// MARK: - GameScene

final class GameScene: Scene {
    // MARK: Lifecycle

    override init() {
        super.init()
        dieSynth.setWaveform(.sawtooth)
        dieSynth.setAttackTime(0.01)
        dieSynth.setDecayTime(0.3)
        dieSynth.setSustainLevel(0.0)
        dieSynth.setReleaseTime(0.2)
    }

    // MARK: Internal

    enum State {
        case waiting
        case playing
        case gameOver
    }

    static let pipeSpeed: Float = 4
    static let pipeFrequency = 35

    var score = Score()
    var frame = 0
    var gameOverTimer: Int = 50

    let waiting = Waiting()
    let player = Player()
    let ground = Ground()
    var pipes: [Pipe] = []

    let dieSynth = Sound.Synth()

    var state: State = .waiting {
        didSet {
            if state == .gameOver {
                dieSynth.playNote(frequency: 440, volume: 0.5, length: 0.5)
                game.highScore = max(game.highScore, score.score)
            }

            if state == .waiting {
                score.removeFromDisplayList()
                waiting.addToDisplayList()
            } else {
                score.addToDisplayList()
                waiting.removeFromDisplayList()
            }
        }
    }

    override func onLoad() {
        super.onLoad()
        player.addToDisplayList()
        ground.addToDisplayList()
        waiting.addToDisplayList()
    }

    override func update() {
        switch (game.scene as? GameScene)?.state {
        case .waiting:
            if !System.buttonState.pushed.intersection([.a, .b, .up, .left, .right, .down]).isEmpty {
                (game.scene as? GameScene)?.state = .playing
            }
        case .playing:
            if frame % Self.pipeFrequency == 0 {
                let pipe = Pipe()
                pipe.addToDisplayList()
                pipes.append(pipe)
            }
            for (index, pipe) in pipes.enumerated().reversed() {
                if pipe.maxX < 0 {
                    score += 1
                    pipe.removeFromDisplayList()
                    pipes.remove(at: index)
                }
            }
        default: break
        }
        frame += 1
        if state == .gameOver { gameOverTimer -= 1 }

        if gameOverTimer == 0 {
            game.scene = GameOverScene(score: score.score)
        }
    }
}

// MARK: - Waiting

final class Waiting: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = Rect(x: 0, y: 0, width: Display.width, height: Display.height)
    }

    // MARK: Internal

    let font11 = try! Graphics.Font(path: "DepartureMono-Regular-11.pft")
    let font33 = try! Graphics.Font(path: "DepartureMono-Regular-33.pft")

    override func update() {
        markDirty()
    }

    override func draw(bounds _: Rect, drawRect _: Rect) {
        Graphics.setFont(font33)
        let text = "Flappy Swift"
        let textWidth = font33.getTextWidth(for: text, tracking: 0)
        Graphics.drawText(
            text,
            at: Point(
                x: (Float(Display.width) / 2) - (Float(textWidth) / 2),
                y: Easing.linear.ease(
                    abs(System.elapsedTime.truncatingRemainder(dividingBy: 2) - 1),
                    scale: 77...83
                )
            )
        )

        Graphics.setFont(font11)
        let buttonText = "Press any button"
        let buttonTextWidth = font11.getTextWidth(for: buttonText, tracking: 0)
        Graphics.drawText(
            buttonText,
            at: Point(x: (Display.width / 2) - (buttonTextWidth / 2), y: 160)
        )
    }
}

// MARK: - Ground

final class Ground: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = Rect(
            x: 0,
            y: Display.height - Self.height,
            width: Display.width,
            height: Self.height
        )
        collideRect = Rect(x: 0, y: 0, width: Display.width, height: Self.height)
        zIndex = 1
    }

    // MARK: Internal

    static let height: Int = 34

    override func draw(bounds: Rect, drawRect _: Rect) {
        let rect = Rect(x: bounds.x, y: bounds.y, width: bounds.width, height: 10)
        Graphics.fillRect(
            bounds,
            color: .pattern((0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77))
        )
        Graphics.fillRect(
            rect,
            color: .pattern((0xF8, 0x7C, 0x3E, 0x1F, 0x8F, 0xC7, 0xE3, 0xF1))
        )
        Graphics.drawRect(rect)
    }
}

typealias Vector = Point

// MARK: - Player

final class Player: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = Rect(x: 40, y: 0, width: 24, height: 24)
        collideRect = Rect(x: 0, y: 0, width: 24, height: 24)
        bounds.center.y = (Float(Display.height) / 2) - 40
        zIndex = 2
        image = Self.image

        flapSynth.setWaveform(.sine)
        flapSynth.setAttackTime(0.001)
        flapSynth.setDecayTime(0.05)
        flapSynth.setSustainLevel(0.0)
        flapSynth.setReleaseTime(0.05)
    }

    // MARK: Internal

    nonisolated(unsafe) static let image = try! Graphics.Bitmap(path: "player.png")
    nonisolated(unsafe) static let imageUp = try! Graphics.Bitmap(path: "player_up.png")
    nonisolated(unsafe) static let imageDown = try! Graphics.Bitmap(path: "player_down.png")

    lazy var velocity = Vector(x: 0, y: jumpVelocity)
    let gravity: Float = 0.5
    let jumpVelocity: Float = -5.0

    override func update() {
        guard (game.scene as? GameScene)?.state != .waiting else { return }

        // Apply gravity
        velocity.y += gravity

        // Jump when button is pressed
        if (game.scene as? GameScene)?.state == .playing,
           !System.buttonState.pushed.intersection([.a, .b, .up, .left, .right, .down]).isEmpty {
            velocity.y = jumpVelocity
            flapSynth.playNote(frequency: 1200, volume: 0.5, length: 0.03)
        }

        if velocity.y > 1 {
            image = Self.imageDown
        } else if velocity.y < -1 {
            image = Self.imageUp
        } else {
            image = Self.image
        }

        // Update position
        let goal = Point(x: position.x, y: position.y + velocity.y)
        let collisionInfo = moveWithCollisions(goal: goal)
        if !collisionInfo.collisions.isEmpty, (game.scene as? GameScene)?.state != .gameOver {
            (game.scene as? GameScene)?.state = .gameOver
        }

        // Clamp position to screen bounds
        bounds.y = max(0, min(bounds.y, Float(Display.height) - bounds.height))
    }

    override func collisionResponse(other _: Sprite.Sprite) -> Sprite.CollisionResponseType {
        .overlap
    }

    // MARK: Private

    private let flapSynth = Sound.Synth()
}

// MARK: - Pipe

final class Pipe {
    // MARK: Lifecycle

    init() {
        let width: Float = 40
        let gap: Float = 80
        let center = Float(Display.height - Ground.height) / 2
        let maxOffset = center - (gap / 2) - 10

        let centerY: Float = .random(in: center - maxOffset...center + maxOffset)

        top = PipePart(
            top: true,
            x: Float(Display.width),
            y: 0,
            width: width,
            height: centerY - gap / 2
        )
        bottom = PipePart(
            top: false,
            x: Float(Display.width),
            y: centerY + gap / 2,
            width: width,
            height: ceilf(Float(Display.height) - (centerY + gap / 2))
        )
    }

    // MARK: Internal

    var maxX: Float { top.bounds.x + top.bounds.width }

    func addToDisplayList() {
        top.addToDisplayList()
        bottom.addToDisplayList()
    }

    func removeFromDisplayList() {
        top.removeFromDisplayList()
        bottom.removeFromDisplayList()
    }

    // MARK: Private

    private let top: PipePart
    private let bottom: PipePart
}

// MARK: - PipePart

final class PipePart: Sprite.Sprite {
    // MARK: Lifecycle

    init(
        top: Bool,
        x: Float,
        y: Float,
        width: Float,
        height: Float
    ) {
        self.top = top
        super.init()
        bounds = Rect(x: x, y: y, width: width, height: height)
        collideRect = Rect(x: 0, y: 0, width: width, height: height)
    }

    // MARK: Internal

    let top: Bool

    override func draw(bounds: Rect, drawRect _: Rect) {
        let lightGray: Graphics.Color = .white
        let gray: Graphics.Color = .pattern((0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA))
        let darkGray: Graphics.Color = .black

        let bottomRect: Rect
        let topRect: Rect
        if top {
            bottomRect = Rect(
                x: bounds.x + 1,
                y: bounds.y,
                width: bounds.width - 2,
                height: bounds.height - 10
            )
            topRect = Rect(
                x: bounds.x,
                y: bounds.height - 10,
                width: bounds.width,
                height: 10
            )
        } else {
            bottomRect = Rect(
                x: bounds.x + 1,
                y: bounds.y + 10,
                width: bounds.width - 2,
                height: bounds.height - 10
            )
            topRect = Rect(
                x: bounds.x,
                y: bounds.y,
                width: bounds.width,
                height: 10
            )
        }
        let bottomRectShadow = Rect(
            x: bottomRect.x + bottomRect.width - 6,
            y: bottomRect.y,
            width: 6,
            height: bottomRect.height
        )
        let topRectShadow = Rect(
            x: topRect.x + topRect.width - 6,
            y: topRect.y,
            width: 6,
            height: topRect.height
        )
        let bottomRectHighlight = Rect(
            x: bottomRect.x,
            y: bottomRect.y,
            width: 8,
            height: bottomRect.height
        )
        let topRectHighlight = Rect(
            x: topRect.x,
            y: topRect.y,
            width: 8,
            height: topRect.height
        )
        Graphics.fillRect(bottomRect, color: gray)
        Graphics.fillRect(bottomRectShadow, color: darkGray)
        Graphics.fillRect(bottomRectHighlight, color: lightGray)
        Graphics.fillRect(topRect, color: gray)
        Graphics.fillRect(topRectShadow, color: darkGray)
        Graphics.fillRect(topRectHighlight, color: lightGray)
        Graphics.drawRect(bottomRect)
        Graphics.drawRect(topRect)
    }

    override func update() {
        guard (game.scene as? GameScene)?.state == .playing else { return }
        var goal = position
        goal.x -= GameScene.pipeSpeed
        let collisionInfo = moveWithCollisions(goal: goal)
        if !collisionInfo.collisions.filter({ $0.other is Player }).isEmpty {
            (game.scene as? GameScene)?.state = .gameOver
        }
    }

    override func collisionResponse(other _: Sprite.Sprite) -> Sprite.CollisionResponseType {
        .overlap
    }
}

// MARK: - Score

final class Score: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        let textWidth = font.getTextWidth(for: "000", tracking: 0)
        let width = textWidth + 8
        bounds = Rect(x: (Display.width / 2) - (width / 2), y: 10, width: width, height: font.height + 8)
        zIndex = 1
    }

    // MARK: Internal

    private(set) var score = 0 {
        didSet { markDirty() }
    }

    override func draw(bounds: Rect, drawRect _: Rect) {
        Graphics.setFont(font)
        Graphics.fillRect(bounds, color: .white)
        Graphics.drawRect(bounds)
        var text = "\(score)"
        text = String(repeating: "0", count: max(3 - text.utf8.count, 0)) + text
        Graphics.drawText(
            text,
            at: Point(
                x: bounds.origin.x + 4,
                y: bounds.center.y - (Float(font.height) / 2)
            )
        )
    }

    static func += (lhs: Score, rhs: Int) {
        lhs.score += rhs
    }

    // MARK: Private

    private let font = try! Graphics.Font(path: "DepartureMono-Regular-22.pft")
}
