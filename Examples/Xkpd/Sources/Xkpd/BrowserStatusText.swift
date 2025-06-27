import PlaydateKit

class BrowserStatusText: Sprite.Sprite {
    // MARK: Lifecycle

    override init() {
        super.init()

        setSize(width: 280, height: 120)
        moveTo(Point(
            x: Display.width / 2,
            y: Display.height / 2 + 40,
        ))
        setIgnoresDrawOffset(true)
    }

    // MARK: Public

    public var line1: String = ""

    public var line2: String = ""

    // MARK: Internal

    override func draw(bounds _: Rect, drawRect _: Rect) {
        Graphics.drawMode = .fillBlack

        Graphics.setFont(Font.NicoBold16)
        Graphics.drawTextInRect(line1, in: Rect(
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: Float(Font.NicoBold16.height),
        ), wrap: .clip, aligned: .center)

        Graphics.setFont(Font.NicoClean16)
        Graphics.drawTextInRect(line2, in: Rect(
            x: bounds.x,
            y: bounds.y + 25,
            width: bounds.width,
            height: Float(Font.NicoClean16.height * 4),
        ), wrap: .word, aligned: .center)
    }
}
