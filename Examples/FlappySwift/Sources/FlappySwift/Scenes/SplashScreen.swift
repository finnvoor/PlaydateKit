import PlaydateKit

final class SplashScreen: Scene {
    // MARK: Lifecycle

    override init() {
        super.init()
        bounds = Rect(x: 0, y: 0, width: Display.width, height: Display.height)
    }

    // MARK: Internal

    let duration: Float = 4
    let font = try! Graphics.Font(path: "DepartureMono-Regular-33.pft")
    lazy var width = font.getTextWidth(for: "made with swift", tracking: 0)
    lazy var width1 = font.getTextWidth(for: "made ", tracking: 0)
    lazy var width2 = font.getTextWidth(for: "made with ", tracking: 0)

    override func onLoad() {
        super.onLoad()
        System.resetElapsedTime()
    }

    override func draw(bounds: Rect, drawRect _: Rect) {
        Graphics.setFont(font)
        Graphics.drawText(
            "made",
            at: Point(
                x: bounds.center.x - Float(width / 2),
                y: Easing.outBounce.ease(
                    System.elapsedTime,
                    duration: 1.5,
                    scale: 0...Float(Display.height) / 2
                ) - Float(font.height)
            )
        )
        Graphics.drawText(
            "with",
            at: Point(
                x: (bounds.center.x - Float(width / 2)) + Float(width1),
                y: Easing.outBounce.ease(
                    System.elapsedTime - 0.8,
                    duration: 1.5,
                    scale: 0...Float(Display.height) / 2
                ) - Float(font.height)
            )
        )
        Graphics.drawText(
            "swift",
            at: Point(
                x: (bounds.center.x - Float(width / 2)) + Float(width2),
                y: Easing.outBounce.ease(
                    System.elapsedTime - 1.6,
                    duration: 1.5,
                    scale: 0...Float(Display.height) / 2
                ) - Float(font.height)
            )
        )
    }

    override func update() {
        markDirty()
        if System.elapsedTime > duration {
            game.scene = GameScene()
        }
    }
}
