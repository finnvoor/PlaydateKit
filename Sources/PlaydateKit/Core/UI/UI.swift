public enum UI {
    public final class CrankIndicator {
        private var lastScale: Display.Scale?
        private var bubbleX: Int = 0
        private var bubbleY: Int = 0
        private var bubbleWidth: Int = 0
        private var bubbleHeight: Int = 0
        private var bubbleImage: Graphics.Bitmap?

        private var lastTime: CUnsignedInt = 0
        private var currentFrame: Int = 1
        private var currentScale: Display.Scale?

        private var crankIndicatorY: Int = 0

        private var bubbleFlip: Graphics.Bitmap.Flip = .unflipped
        private var textOffset = 76

        private var crankFrames: Graphics.BitmapTable?
        private var frameCount = 0

        private var textFrameImage: Graphics.Bitmap?
        private var textFrameCount = 14

        public var clockwise: Bool

        public init(clockwise: Bool = true) {
            self.clockwise = clockwise
        }

        public func draw(xOffset: Int = 0, yOffset: Int = 0) throws(Playdate.Error) {

            var xOffset = xOffset
            var yOffset = yOffset

            let scale = Display.scale

            if currentScale?.rawValue != scale.rawValue {
                try loadImages(for: scale)
            }

            guard let bubbleImage else { throw Playdate.Error(description: "bubbleImage not loaded") }
            guard let crankFrames else { throw Playdate.Error(description: "crankFrames not loaded") }

            let currentTime = System.currentTimeMilliseconds
            var delta = currentTime - lastTime

            // reset to start frame if :draw() hasn't been called in more than a second
            if delta > 1000 {
                currentFrame = 1
                delta = 0
                lastTime = currentTime
            }

            // calculate how many frames the animation should jump ahead (how long has it been since this was last called?)
            while delta >= 49 {
                lastTime += 50
                delta -= 50
                currentFrame += 1
                if currentFrame > frameCount {
                    currentFrame = 1
                }
            }

            Graphics.pushContext()

            Graphics.drawBitmap(bubbleImage, at: Point(x: bubbleX + xOffset, y: bubbleY + yOffset), flip: bubbleFlip)

            if scale.rawValue > 2 || currentFrame > textFrameCount {
                var frame: Graphics.Bitmap?

                if clockwise {
                    let frameIndex = (currentFrame - textFrameCount - 1) % crankFrames.imageCount
                    frame = crankFrames.bitmap(at: frameIndex)
                } else {
                    let frameIndex = crankFrames.imageCount - (currentFrame - textFrameCount - 1) % crankFrames.imageCount
                    frame = crankFrames.bitmap(at: frameIndex - 1)
                }

                guard let frame else { throw Playdate.Error(description: "frame not loaded") }

                switch scale {
                case .twoTimes, .fourTimes:
                    yOffset += 1
                default: break
                }

                let (frameWidth, frameHeight, _) = frame.getData(mask: nil, data: nil)

                Graphics.drawBitmap(
                    frame,
                    at: Point(
                        x: (bubbleX + xOffset + (textOffset - frameWidth) / 2),
                        y: (bubbleY + yOffset + (bubbleHeight - frameHeight) / 2)
                    )
                )
            } else {

                // draw text
                if let textFrameImage {
                    let (textWidth, textHeight, _) = textFrameImage.getData(mask: nil, data: nil)
                    if case .twoTimes = scale {
                        xOffset -= 1
                    }
                    Graphics.drawBitmap(
                        textFrameImage,
                        at: Point(
                            x: (bubbleX + xOffset + (textOffset - textWidth) / 2),
                            y: (bubbleY + yOffset + (bubbleHeight - textHeight) / 2)
                        )
                    )
                }
            }

            Graphics.popContext()
        }

        public func bounds(xOffset: Int = 0, yOffset: Int = 0) throws(Playdate.Error) -> Rect {
            if Display.scale.rawValue != lastScale?.rawValue {
                lastScale = Display.scale
                try loadImages(for: Display.scale)
            }

            return Rect(
                x: Float(bubbleX + xOffset),
                y: Float(bubbleY + yOffset),
                width: Float(bubbleWidth),
                height: Float(bubbleHeight)
            )
        }

        public func resetAnimation() {
            lastTime = System.currentTimeMilliseconds
            currentFrame = 1
        }

        private func loadImages(for scale: Display.Scale) throws(Playdate.Error) {

            lastTime = 0
            currentFrame = 1
            currentScale = Display.scale

            crankIndicatorY = 210 / Int(scale.rawValue)

            let imagePath = "crank-notice-bubble-\(scale.rawValue)x.png"
            bubbleImage = try Graphics.Bitmap(path: imagePath)

            if let bubbleImage {
                (bubbleWidth, bubbleHeight, _) = bubbleImage.getData(mask: nil, data: nil)

                if System.flipped {
                    bubbleX = 0
                    bubbleY = Display.height - crankIndicatorY - bubbleHeight / 2
                    bubbleFlip = .flippedXY
                    textOffset = 100 / Int(scale.rawValue)
                } else {
                    bubbleX = Display.width - bubbleWidth
                    bubbleY = crankIndicatorY - bubbleHeight / 2
                    bubbleFlip = .unflipped
                    textOffset = 76 / Int(scale.rawValue)
                }

                crankFrames = try Graphics.BitmapTable(path: "crank-frames-\(scale.rawValue)x.png")
                frameCount = (crankFrames?.imageCount ?? 0) * 3

                switch scale {
                case .oneTimes, .twoTimes:
                    textFrameImage = try Graphics.Bitmap(path: "crank-notice-text-\(scale.rawValue)x.png")
                    textFrameCount = 14
                    frameCount += textFrameCount
                default:
                    textFrameImage = nil
                    textFrameCount = 0
                }
            }
        }
    }
}
