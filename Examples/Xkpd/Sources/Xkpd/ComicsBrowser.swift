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
                    Graphics.drawText("Loading latest (#\(comic.num))", at: Point.zero)
                } else {
                    Graphics.drawText("Loading latest", at: Point.zero)
                }
            } else {
                Graphics.drawText("Loading comic #\(comic.num)", at: Point.zero)
            }
        }


        let y2 = Point(x: 0, y: 20)

        switch comic.state {
        case .loadingMetadataHeaders:
            if hasMenuItems {
                System.removeAllMenuItems()
                hasMenuItems = false
            }
            Graphics.drawText("Loading metadata", at: y2)
        case .loadingMetadata:
            if let progress = comic.connection?.progress {
                Graphics.drawText("Loading metadata \(comic.connection!.bytesAvailable) / \(progress.1)", at: y2)
            }
        case .loadingImageHeaders:
            Graphics.drawText("Loading image", at: y2)
        case .loadingImage:
            if let progress = comic.connection?.progress {
                Graphics.drawText("Loading image \(comic.connection!.bytesAvailable) / \(progress.1)", at: y2)
            }
        case .loaded:
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
            Graphics.drawText(message, at: y2)
        }
    }

    // MARK: Private

    private static let scrollSpeed: Float = 10

    private static let margin = 4

    private var comic: Comic

    private var drawOffX = ComicsBrowser.margin

    private var drawOffY = ComicsBrowser.margin

    private var latestNum = 1

    private var hasMenuItems = false

    private let goto = Goto()

    private var gotoActive = false

    private func resetDrawOffset() {
        drawOffX = ComicsBrowser.margin
        drawOffY = ComicsBrowser.margin
        Graphics.setDrawOffset(dx: drawOffX, dy: drawOffY)
    }

    private func prev() {
        comic = Comic(num: comic.num - 1)

        resetDrawOffset()
    }

    private func next() {
        if comic.isLatest || comic.num >= latestNum {
            comic = Comic()
        } else {
            comic = Comic(num: comic.num + 1)
        }

        resetDrawOffset()
    }

    private func updateInput() {
        let pushed = System.buttonState.pushed
        let current = System.buttonState.current

        if pushed.contains(.b) && comic.num > 1 {
            prev()
            return
        } else if pushed.contains(.a) {
            next()
            return
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

        drawOffX += Int(scrollDir.x)
        drawOffY += Int(scrollDir.y)

        drawOffX = min(max(minOffX, drawOffX), m)
        drawOffY = min(max(minOffY, drawOffY), m)

        Graphics.setDrawOffset(dx: drawOffX, dy: drawOffY)
    }

    private func setUpMenuItems() {
        System.addMenuItem(title: "GOTO") {
            self.goto.addToDisplayList()
            self.gotoActive = true
        }

        System.addMenuItem(title: "Latest") {
            self.resetDrawOffset()
            self.comic = Comic()
        }

        System.addMenuItem(title: "Random") {
            self.resetDrawOffset()
            self.comic = Comic(num: Int.random(in: 1...self.latestNum, using: &RNG.instance))
        }

        hasMenuItems = true
    }

    private func updateGoto() {
        let pushed = System.buttonState.pushed

        if pushed.contains(.a) {
            goto.removeFromDisplayList()
            gotoActive = false

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
        }
    }
}
