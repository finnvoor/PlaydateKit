import PlaydateKit

class ComicsBrowser {
    // MARK: Lifecycle

    init() {
        self.comic = Comic()
    }

    // MARK: Internal

    func update() {
        Sprite.updateAndDrawDisplayListSprites()

        if gotoActive {
            updateGoto()
            return
        }

        switch comic.state {
        case .loaded:
            break
        default:
            if comic.isLatest {
                if comic.num > 0 {
                    statusText.line1 = "Loading latest comic (#\(comic.num))"
                } else {
                    statusText.line1 = "Loading latest comic"
                }
            } else {
                statusText.line1 = "Loading comic #\(comic.num)"
            }
        }

        switch comic.state {
        case .loadingMetadataHeaders:
            statusText.addToDisplayList()
            statusText.line2 = "Downloading metadata headers"

            if hasMenuItems {
                System.removeAllMenuItems()
                hasMenuItems = false
            }
        case .loadingMetadata:
            if let progress = comic.connection?.progress {
                statusText.line2 = "Downloading metadata \(comic.connection!.bytesAvailable) / \(progress.1) bytes"
            }
        case .loadingImageHeaders:
            statusText.line2 = "Downloading image headers"
        case .loadingImage:
            if let progress = comic.connection?.progress {
                statusText.line2 = "Downloading image \(comic.connection!.bytesAvailable) / \(progress.1) bytes"
            }
        case .loaded:
            statusText.removeFromDisplayList()
            if !hasMenuItems {
                setUpMenuItems()
            }

            if comic.isLatest && latestNum != comic.num {
                latestNum = comic.num
            }

            updateInput()
        case .error(let message):
            if !hasMenuItems {
                setUpMenuItems()
            }

            updateInput()
            statusText.line2 = message
        }
    }

    func onWillPause() {
        let frame = Graphics.getDisplayBufferBitmap()!
        let menuBmp = frame.copy()

        Graphics.pushContext(menuBmp)
        Graphics.fillRect(Rect(
            x: 0,
            y: 0,
            width: Display.width,
            height: Display.height
        ), color: .black(opacity: 0.5))

        if let qrBmp = comic.qrBitmap {
            Graphics.fillRoundRect(Rect(
                x: 46,
                y: 15,
                width: 109,
                height: 109 + 22,
            ), radius: 3, color: .black)

            Graphics.drawRoundRect(Rect(
                x: 52,
                y: 21,
                width: 97,
                height: 97 + 22,
            ), radius: 0, lineWidth: 2, color: .white)

            Graphics.drawMode = .copy
            Graphics.drawBitmap(qrBmp, at: Point(
                x: 63,
                y: 32,
            ))

            Graphics.setFont(Font.NicoBold16)
            Graphics.drawMode = .fillWhite
            Graphics.drawTextInRect("#\(comic.num)", in: Rect(
                x: 63,
                y: 115,
                width: 75,
                height: Font.NicoBold16.height
            ), aligned: .center)

        }

        Graphics.popContext()

        System.setMenuImage(menuBmp)
    }

    // MARK: Private

    private static let scrollSpeed: Float = 10

    private static let margin = 4

    private let statusText = BrowserStatusText()

    private var comic: Comic {
        didSet {
            resetDrawOffset()
            hideInfoBox()

            self.gotoActive = false
            self.goto.removeFromDisplayList()
        }
    }

    private var drawOffX = ComicsBrowser.margin

    private var drawOffY = ComicsBrowser.margin

    private var latestNum = 1

    private var hasMenuItems = false

    private let goto = Goto()

    private var gotoActive = false

    private var infoBox: InfoBox? = nil

    private var hasBumpedX = false

    private var hasBumpedY = false

    private func resetDrawOffset() {
        drawOffX = ComicsBrowser.margin
        drawOffY = ComicsBrowser.margin
        Graphics.setDrawOffset(dx: drawOffX, dy: drawOffY)
    }

    private func prev() {
        if infoBox != nil {
            return
        }

        comic = Comic(num: comic.num - 1)

        SFX.instance.play(.prevComic)
    }

    private func next() {
        if infoBox != nil {
            return
        }

        if comic.isLatest || comic.num >= latestNum {
            comic = Comic()
        } else {
            comic = Comic(num: comic.num + 1)
        }

        SFX.instance.play(.nextComic)
    }

    private func updateInput() {
        let pushed = System.buttonState.pushed
        let current = System.buttonState.current
        let released = System.buttonState.released

        if pushed.contains(.b) {
            toggleInfoBox()
        }

        let m = Self.margin
        let minOffX = -(comic.imgWidth + m - Display.width)
        let minOffY = -(comic.imgHeight + m - Display.height)

        if pushed.contains(.left) && drawOffX == m {
            prev()
            return
        } else if pushed.contains(.right) && drawOffX <= minOffX {
            next()
            return
        }

        var scrollDir = Vector2(x: 0, y: 0)
        if current.contains(.up) {
            scrollDir.y = 1
        } else if current.contains(.down) {
            scrollDir.y = -1
        }

        if current.contains(.right) {
            scrollDir.x = -1
        } else if current.contains(.left) {
            scrollDir.x = 1
        }

        scrollDir = scrollDir.normalized() * Self.scrollSpeed

        // Set up bumps
        let wantsScrollX = scrollDir.x != 0
        let wantsScrollY = scrollDir.y != 0
        let lastDrawOffX = drawOffX
        let lastDrawOffY = drawOffY

        // Scroll
        drawOffX += Int(scrollDir.x)
        drawOffY += Int(scrollDir.y)

        drawOffX = min(max(minOffX, drawOffX), m)
        drawOffY = min(max(minOffY, drawOffY), m)

        // Play bumps
        if wantsScrollX && lastDrawOffX == drawOffX && !hasBumpedX {
            hasBumpedX = true
            SFX.instance.play(.scrollEdge)
        }

        if wantsScrollY && lastDrawOffY == drawOffY && !hasBumpedY {
            hasBumpedY = true
            SFX.instance.play(.scrollEdge)
        }

        // Play scrolling
        if (wantsScrollX && !hasBumpedX) || (wantsScrollY && !hasBumpedY) {
            SFX.instance.start(.scrolling)
        } else if (!wantsScrollX || !wantsScrollY) {
            SFX.instance.stop(.scrolling)
        }

        Graphics.setDrawOffset(dx: drawOffX, dy: drawOffY)

        // Reset bumps
        if released.contains(.left) || released.contains(.right) {
            hasBumpedX = false
        }

        if released.contains(.up) || released.contains(.down) {
            hasBumpedY = false
        }
    }

    private func setUpMenuItems() {
        System.addMenuItem(title: "GOTO") {
            self.goto.addToDisplayList()
            self.gotoActive = true
        }

        System.addMenuItem(title: "Latest") {
            self.comic = Comic()
        }

        System.addMenuItem(title: "Random") {
            self.comic = Comic(num: Int.random(in: 1...self.latestNum, using: &RNG.instance))
        }

        hasMenuItems = true
    }

    private func updateGoto() {
        let pushed = System.buttonState.pushed

        if pushed.contains(.a) {
            goto.removeFromDisplayList()
            gotoActive = false

            SFX.instance.play(.goto)

            comic = Comic(num: self.goto.num)
            return
        }

        if pushed.contains(.up) {
            goto.increment()
        } else if pushed.contains(.down) {
            goto.decrement()
        }

        if pushed.contains(.left) {
            goto.selectPreviousNum()
        } else if pushed.contains(.right) {
            goto.selectNextNum()
        }

        if pushed.contains(.b) {
            goto.removeFromDisplayList()
            gotoActive = false
            SFX.instance.play(.dismissWindow)
        }
    }

    private func toggleInfoBox() {
        if infoBox != nil {
            hideInfoBox()
            SFX.instance.play(.dismissWindow)
        } else {
            showInfoBox()
        }
    }

    private func showInfoBox() {
        if comic.num == 0 {
            return
        }

        infoBox = InfoBox(
            num: comic.num,
            title: comic.title,
            dateString: "\(comic.year)/\(comic.month)/\(comic.day)",
            alt: comic.alt,
        )
        infoBox?.addToDisplayList()

        SFX.instance.play(.showInfo)
    }

    private func hideInfoBox() {
        guard let infoBox else {
            return
        }

        infoBox.removeFromDisplayList()
        self.infoBox = nil
    }
}
