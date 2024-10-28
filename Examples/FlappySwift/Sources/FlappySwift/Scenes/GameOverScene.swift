import PlaydateKit

// MARK: - GameOverScene

final class GameOverScene: Scene {
    // MARK: Lifecycle

    init(score: Int) {
        self.score = score
        super.init()
        bounds = Rect(x: 0, y: 0, width: Display.width, height: Display.height)
    }

    // MARK: Internal

    let font11 = try! Graphics.Font(path: "DepartureMono-Regular-11.pft")
    let font22 = try! Graphics.Font(path: "DepartureMono-Regular-22.pft")
    let font33 = try! Graphics.Font(path: "DepartureMono-Regular-33.pft")

    override func draw(bounds: Rect, drawRect _: Rect) {
        Graphics.setFont(font33)
        let textWidth = font33.getTextWidth(for: "Game Over", tracking: 0)
        Graphics.drawText(
            "Game Over",
            at: Point(
                x: bounds.center.x - Float(textWidth / 2),
                y: 20
            )
        )

        if score == game.highScore {
            Graphics.drawText("New", at: Point(x: 110, y: 86))
            Graphics.drawText("Best!", at: Point(x: 110, y: 118))
        }

        let rect = Rect(
            x: (Display.width / 2) - (200 / 2),
            y: 74,
            width: 200,
            height: 100
        )
        Graphics.drawRect(rect)
        Graphics.drawRect(rect.insetBy(left: 2, right: 2, top: 2, bottom: 2))

        Graphics.setFont(font11)
        Graphics.drawText(
            "Score",
            at: Point(
                x: 256,
                y: 80
            )
        )

        Graphics.drawText(
            "Best",
            at: Point(
                x: 263,
                y: 130
            )
        )

        let playAgain = "Press any button to play again"
        let playAgainWidth = font11.getTextWidth(for: playAgain, tracking: 0)
        Graphics.drawText(
            playAgain,
            at: Point(x: (Display.width / 2) - (playAgainWidth / 2), y: 200)
        )

        Graphics.setFont(font22)

        var score = "\(score)"
        score = String(repeating: "0", count: max(3 - score.utf8.count, 0)) + score
        var best = "\(game.highScore)"
        best = String(repeating: "0", count: max(3 - best.utf8.count, 0)) + best

        Graphics.drawText(
            score,
            at: Point(
                x: 250,
                y: 90
            )
        )

        Graphics.drawText(
            best,
            at: Point(
                x: 250,
                y: 140
            )
        )
    }

    override func update() {
        if !System.buttonState.pushed.intersection([.a, .b, .up, .left, .right, .down]).isEmpty {
            game.scene = GameScene()
        }
    }

    // MARK: Private

    private let score: Int
}

extension Rect {
    func insetBy(left: Float, right: Float, top: Float, bottom: Float) -> Rect {
        Rect(x: x + left, y: y + top, width: width - left - right, height: height - top - bottom)
    }
}
