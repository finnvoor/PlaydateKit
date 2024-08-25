import PlaydateKit

// MARK: - Game

final class Game: PlaydateGame {
    // MARK: Lifecycle

    init() {
        [
            playerPaddle, computerPaddle,
            ball,
            topWall, bottomWall, leftWall, rightWall
        ].forEach { $0.addToDisplayList() }

        playerPaddle.position = Point(x: 10, y: (Float(Display.height) / 2) - (playerPaddle.bounds.height / 2))
        computerPaddle.position = Point(
            x: Float(Display.width - 10) - computerPaddle.bounds.width,
            y: Float(Display.height / 2) - (computerPaddle.bounds.height / 2)
        )
        ball.position = Point(x: Display.width / 2, y: 10)
    }

    // MARK: Internal

    enum State {
        case playing
        case gameOver
    }

    var state: State = .playing
    var score: (player: Int, computer: Int) = (0, 0)
    let winningScore = 11
    let playerPaddle = PlayerPaddle()
    let computerPaddle = ComputerPaddle()
    let ball = Ball()

    let topWall = Wall(bounds: Rect(x: 0, y: -1, width: Display.width, height: 1))
    let bottomWall = Wall(bounds: Rect(x: 0, y: Display.height, width: Display.width, height: 1))
    let leftWall = Wall(bounds: Rect(x: -1, y: 0, width: 1, height: Display.height))
    let rightWall = Wall(bounds: Rect(x: Display.width, y: 0, width: 1, height: Display.height))

    var hasWinner: Bool { score.player >= winningScore || score.computer >= winningScore }

    func update() -> Bool {
        switch state {
        case .playing:
            Sprite.updateAndDrawDisplayListSprites()
        case .gameOver:
            if System.buttonState.current.contains(.a) {
                score = (0, 0)
                state = .playing
            }

            // TODO: - Center properly
            Graphics.drawText(
                "Game Over",
                at: Point(x: (Display.width / 2) - 40, y: (Display.height / 2) - 20)
            )
            Graphics.drawText(
                "Press Ⓐ to play again",
                at: Point(x: (Display.width / 2) - 80, y: Display.height / 2)
            )
        }

        Graphics.drawText("\(score.player)", at: Point(x: (Display.width / 2) - 80, y: 10))
        Graphics.drawText("\(score.computer)", at: Point(x: (Display.width / 2) + 80, y: 10))
        Graphics.drawLine(
            Line(
                start: Point(x: Display.width / 2, y: 0),
                end: Point(x: Display.width / 2, y: Display.height)
            ),
            lineWidth: 1,
            color: .pattern((0x0, 0x0, 0xFF, 0xFF, 0x0, 0x0, 0xFF, 0xFF))
        )

        return true
    }
}

// MARK: - Wall

class Wall: Sprite.Sprite {
    init(bounds: Rect) {
        super.init()
        self.bounds = bounds
        collideRect = Rect(origin: .zero, width: bounds.width, height: bounds.height)
    }
}

// MARK: - Ball

typealias Vector = Point

// MARK: - Ball

class Ball: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = .init(x: 0, y: 0, width: 8, height: 8)
        collideRect = bounds
    }

    // MARK: Internal

    var velocity = Vector(x: 4, y: 5)

    func reset() {
        position = Point(x: Display.width / 2, y: 10)
        velocity.x *= Bool.random() ? 1 : -1
        velocity.y = abs(velocity.y)
    }

    override func update() {
        let collisionInfo = moveWithCollisions(
            goal: position + velocity
        )
        for collision in collisionInfo.collisions {
            if collision.other == game.leftWall {
                game.score.computer += 1
                game.ball.reset()
                if game.hasWinner { game.state = .gameOver }
            } else if collision.other == game.rightWall {
                game.score.player += 1
                game.ball.reset()
                if game.hasWinner { game.state = .gameOver }
            } else {
                synth.playNote(frequency: 220.0, volume: 0.7, length: 0.1)
                if collision.normal.x != 0 {
                    velocity.x *= -1
                }
                if collision.normal.y != 0 {
                    velocity.y *= -1
                }
            }
        }
    }

    /// Setting to `.slide` prevents the ball from getting stuck between the paddle and top/bottom.
    override func collisionResponse(other _: Sprite.Sprite) -> Sprite.CollisionResponseType {
        .slide
    }

    override func draw(bounds: Rect, drawRect _: Rect) {
        Graphics.fillEllipse(in: bounds)
    }

    // MARK: Private

    private let synth: Sound.Synth = {
        let synth = Sound.Synth()
        synth.setWaveform(.square)
        synth.setAttackTime(0.001)
        synth.setDecayTime(0.05)
        synth.setSustainLevel(0.0)
        synth.setReleaseTime(0.05)
        return synth
    }()
}

// MARK: - ComputerPaddle

class ComputerPaddle: Paddle {
    override func update() {
        let ball = game.ball
        let paddleCenter = position.y + bounds.height / 2
        let ballCenter = ball.position.y + ball.bounds.height / 2

        if ballCenter < paddleCenter - 5 {
            // Ball is above the paddle center
            moveWithCollisions(
                goal: position - Vector(x: 0, y: speed)
            )
        } else if ballCenter > paddleCenter + 5 {
            // Ball is below the paddle center
            moveWithCollisions(
                goal: position + Vector(x: 0, y: speed)
            )
        }
        // If the ball is within 5 pixels of the paddle center, don't move
    }
}

// MARK: - PlayerPaddle

class PlayerPaddle: Paddle {
    override func update() {
        if System.isCrankDocked{
            if System.buttonState.current.contains(.down) {
                moveWithCollisions(
                    goal: position + Vector(x: 0, y: speed)
                )
            }
            if System.buttonState.current.contains(.up) {
                moveWithCollisions(
                    goal: position - Vector(x: 0, y: speed)
                )
            }
        }else{
            /// 0 at the top, 1 at the bottom
            let zeroToOne :Float = (180 - abs(System.crankAngle-180))/180
            let targetY = zeroToOne * Float(Display.height)
            moveWithCollisions(goal: Point(x:position.x,y:targetY))
        }
    }
}

// MARK: - Paddle

class Paddle: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = .init(x: 0, y: 0, width: 8, height: 48)
        collideRect = bounds
    }

    // MARK: Internal

    let speed: Float = 4.5

    override func draw(bounds: Rect, drawRect _: Rect) {
        Graphics.fillRect(bounds)
    }
}
