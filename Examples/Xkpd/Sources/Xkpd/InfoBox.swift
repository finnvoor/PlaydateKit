import PlaydateKit

class InfoBox: Sprite.Sprite {
    // MARK: Lifecycle

    init(
        num: Int,
        title: String,
        dateString: String,
        alt: String
    ) {
        super.init()

        let metaText = "#\(num) \(dateString)"

        let metaHeight = Font.NicoPups16.height

        let titleWidth = Self.width - Self.padding * 4
        let titleHeight = Font.NicoBold16.getTextHeightForMaxWidth(
            for: title,
            maxWidth: titleWidth,
            wrap: .word,
            tracking: 0,
            extraLeading: 0
        )

        let altWidth = Self.width - Self.padding * 4
        let altHeight = Font.NicoClean16.getTextHeightForMaxWidth(
            for: alt,
            maxWidth: altWidth,
            wrap: .word,
            tracking: 0,
            extraLeading: 0
        )

        let height = metaHeight + titleHeight + altHeight + Self.padding * 5

        image = Graphics.Bitmap(width: Self.width, height: height)

        Graphics.pushContext(image)

        Graphics.fillRoundRect(Rect(
            x: 0,
            y: 0,
            width: Self.width,
            height: height,
        ), radius: 3, color: .black)

        Graphics.drawRoundRect(Rect(
            x: Self.padding,
            y: Self.padding,
            width: Self.width - Self.padding * 2,
            height: height - Self.padding * 2,
        ), radius: 0, lineWidth: 2, color: .white)

        Graphics.drawMode = .fillWhite

        Graphics.setFont(Font.NicoBold16)
        Graphics.drawTextInRect(title, in: Rect(
            x: Self.padding * 2,
            y: Self.padding * 2,
            width: titleWidth,
            height: titleHeight,
        ), wrap: .word)

        Graphics.setFont(Font.NicoPups16)
        Graphics.drawText(metaText, at: Point(
            x: Self.padding * 2,
            y: titleHeight + Self.padding * 2,
        ))

        Graphics.setFont(Font.NicoClean16)
        Graphics.drawTextInRect(alt, in: Rect(
            x: Self.padding * 2,
            y: titleHeight + metaHeight + Self.padding * 3,
            width: altWidth,
            height: altHeight,
        ), wrap: .word)

        Graphics.popContext()

        center = Point(x: 0.5, y: 1)
        moveTo(Point(
            x: Display.width / 2,
            y: Display.height - 10,
        ))
        setIgnoresDrawOffset(true)
    }

    // MARK: Private

    private static let width = 380

    private static let padding = 6
}
