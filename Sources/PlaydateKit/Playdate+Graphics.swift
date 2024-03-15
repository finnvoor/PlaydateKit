public import CPlaydate

// MARK: - Playdate.Graphics

public extension Playdate {
    enum Graphics {
        // MARK: Public

        public enum Video {
            // MARK: Public

            public class Player {
                // MARK: Lifecycle

                /// Opens the pdv file at path and returns a new video player object for rendering its frames.
                public init(path: StaticString) {
                    pointer = video.loadVideo(path.utf8Start).unsafelyUnwrapped
                }

                /// Opens the pdv file at path and returns a new video player object for rendering its frames.
                public init(path: UnsafePointer<CChar>) {
                    pointer = video.loadVideo(path).unsafelyUnwrapped
                }

                deinit { video.freePlayer(pointer) }

                // MARK: Public

                /// Retrieves information about the video.
                public var info: (
                    width: Int32, height: Int32,
                    frameRate: Float,
                    frameCount: Int32, currentFrame: Int32
                ) {
                    var width: Int32 = 0, height: Int32 = 0
                    var frameRate: Float = 0
                    var frameCount: Int32 = 0, currentFrame: Int32 = 0
                    video.getInfo(pointer, &width, &height, &frameRate, &frameCount, &currentFrame)
                    return (width, height, frameRate, frameCount, currentFrame)
                }

                /// Gets the rendering destination for the video player. If no rendering context has been set, a context bitmap with the same
                /// dimensions as the vieo will be allocated.
                public var context: Bitmap {
                    Bitmap(pointer: video.getContext(pointer).unsafelyUnwrapped)
                }

                /// Sets the rendering destination for the video player to the given bitmap.
                public func setContext(_ context: Bitmap) throws(Error) {
                    guard video.setContext(pointer, context.pointer) != 0 else {
                        throw error
                    }
                }

                /// Sets the rendering destination for the video player to the screen.
                public func useScreenContext() {
                    video.useScreenContext(pointer)
                }

                /// Renders frame number `frameNumber` into the current context.
                public func renderFrame(_ frameNumber: Int32) throws(Error) {
                    guard video.renderFrame(pointer, frameNumber) != 0 else {
                        throw error
                    }
                }

                // MARK: Private

                private let pointer: OpaquePointer

                /// Returns the most recent error
                private var error: Error {
                    Error(humanReadableText: video.getError(pointer))
                }
            }

            // MARK: Private

            private static var video: playdate_video { graphics.video.pointee }
        }

        public class Bitmap {
            // MARK: Lifecycle

            init(pointer: OpaquePointer, free: Bool = true) {
                self.pointer = pointer
                self.free = free
            }

            /// Allocates and returns a new `Bitmap` from the file at path. If there is no file at `path`, the function throws.
            public init(path: StaticString) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadBitmap(path.utf8Start, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
                free = true
            }

            /// Allocates and returns a new `Bitmap` from the file at path. If there is no file at `path`, the function throws.
            public init(path: UnsafeMutablePointer<CChar>) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadBitmap(path, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
                free = true
            }

            /// Allocates and returns a new `width` by `height` `Bitmap` filled with `bgcolor`.
            public init(width: Int32, height: Int32, bgColor: Color) {
                pointer = graphics.newBitmap(width, height, bgColor).unsafelyUnwrapped
                free = true
            }

            deinit {
                if free {
                    graphics.freeBitmap(pointer)
                }
            }

            // MARK: Public

            public typealias DrawMode = LCDBitmapDrawMode
            public typealias Flip = LCDBitmapFlip

            /// Gets/sets a `mask` image for the bitmap, or returns nil if the bitmap doesn’t have a mask layer.
            /// The set mask must be the same size as the target bitmap. The returned mask points to bitmap's data,
            /// so drawing into the mask image affects the source bitmap directly.
            public var mask: Bitmap? {
                get { graphics.getBitmapMask(pointer).map { Bitmap(pointer: $0) } }
                set { graphics.setBitmapMask(pointer, newValue?.pointer) }
            }

            /// Loads the image at `path` into the bitmap.
            public func load(from path: StaticString) throws(Error) {
                var error: UnsafePointer<CChar>?
                graphics.loadIntoBitmap(path.utf8Start, pointer, &error)
                if let error { throw Error(humanReadableText: error) }
            }

            /// Loads the image at `path` into the bitmap.
            public func load(from path: UnsafeMutablePointer<CChar>) throws(Error) {
                var error: UnsafePointer<CChar>?
                graphics.loadIntoBitmap(path, pointer, &error)
                if let error { throw Error(humanReadableText: error) }
            }

            /// Clears the bitmap, filling with the given `bgcolor`.
            public func clear(bgColor: Color) {
                graphics.clearBitmap(pointer, bgColor)
            }

            /// Returns a new LCDBitmap that is an exact copy of the bitmap.
            public func copy() -> Bitmap {
                let bitmap = graphics.copyBitmap(pointer).unsafelyUnwrapped
                return Bitmap(pointer: bitmap)
            }

            /// Gets various info about the bitmap including its `width` and `height` and raw pixel `data`.
            /// The data is 1 bit per pixel packed format, in MSB order; in other words, the high bit of the first byte
            /// in data is the top left pixel of the image. If the bitmap has a mask, a pointer to its data is returned in `mask`,
            /// else nil is returned.
            public func getData(
                mask: inout UnsafeMutablePointer<UInt8>?,
                data: inout UnsafeMutablePointer<UInt8>?
            ) -> (
                width: Int32, height: Int32, rowBytes: Int32
            ) {
                var width: Int32 = 0, height: Int32 = 0, rowBytes: Int32 = 0
                graphics.getBitmapData(pointer, &width, &height, &rowBytes, &mask, &data)
                return (width, height, rowBytes)
            }

            /// Returns a new, rotated and scaled `Bitmap` based on the given `bitmap`.
            public func rotated(by rotation: Float, xScale: Float, yScale: Float) -> (bitmap: Bitmap, allocatedSize: Int32) {
                var allocatedSize: Int32 = 0
                let bitmap = graphics.rotatedBitmap(pointer, rotation, xScale, yScale, &allocatedSize).unsafelyUnwrapped
                return (Bitmap(pointer: bitmap), allocatedSize)
            }

            // MARK: Internal

            let pointer: OpaquePointer

            // MARK: Private

            private let free: Bool
        }

        public typealias LineCapStyle = LCDLineCapStyle
        public typealias Color = LCDColor
        public typealias Rect = LCDRect
        public typealias StringEncoding = PDStringEncoding
        public typealias PolygonFillRule = LCDPolygonFillRule
        public typealias SolidColor = LCDSolidColor

        public class BitmapTable {
            // MARK: Lifecycle

            /// Allocates and returns a new `BitmapTable` from the file at `path`. If there is no file at `path`, the function throws an error.
            public init(path: StaticString) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadBitmapTable(path.utf8Start, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
            }

            /// Allocates and returns a new `BitmapTable` from the file at `path`. If there is no file at `path`, the function throws an error.
            public init(path: UnsafeMutablePointer<CChar>) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadBitmapTable(path, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
            }

            /// Allocates and returns a new `BitmapTable` that can hold `count` `width` by `height` `Bitmaps`.
            public init(count: Int32, width: Int32, height: Int32) {
                pointer = graphics.newBitmapTable(count, width, height).unsafelyUnwrapped
            }

            deinit { graphics.freeBitmapTable(pointer) }

            // MARK: Public

            /// Returns the `index` bitmap in `table`, If `index` is out of bounds, the function returns nil.
            public func bitmap(at index: Int32) -> Bitmap? {
                graphics.getTableBitmap(pointer, index).map { Bitmap(pointer: $0) }
            }

            /// Loads the image table at `path` into the previously allocated `table`.
            public func load(from path: StaticString) throws(Error) {
                var error: UnsafePointer<CChar>?
                graphics.loadIntoBitmapTable(path.utf8Start, pointer, &error)
                if let error { throw Error(humanReadableText: error) }
            }

            /// Loads the image table at `path` into the previously allocated `table`.
            public func load(from path: UnsafeMutablePointer<CChar>) throws(Error) {
                var error: UnsafePointer<CChar>?
                graphics.loadIntoBitmapTable(path, pointer, &error)
                if let error { throw Error(humanReadableText: error) }
            }

            // MARK: Private

            private let pointer: OpaquePointer
        }

        public class Font {
            // MARK: Lifecycle

            /// Returns a `Font` object for the font file at `path`.
            init(path: StaticString) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadFont(path.utf8Start, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
            }

            /// Returns a `Font` object for the font file at `path`.
            init(path: UnsafeMutablePointer<CChar>) throws(Error) {
                var error: UnsafePointer<CChar>?
                let pointer = graphics.loadFont(path, &error)
                if let error { throw Error(humanReadableText: error) }
                self.pointer = pointer.unsafelyUnwrapped
            }

            /// Returns a `Font` object wrapping the `LCDFontData` `data` comprising the contents (minus 16-byte header)
            /// of an uncompressed pft file. `wide` corresponds to the flag in the header indicating whether the font contains
            /// glyphs at codepoints above U+1FFFF.
            init?(data: OpaquePointer, wide: Bool) {
                guard let pointer = graphics.makeFontFromData(data, wide ? 1 : 0) else {
                    return nil
                }
                self.pointer = pointer
            }

            deinit {
                System.realloc(pointer: UnsafeMutableRawPointer(pointer), size: 0)
            }

            // MARK: Public

            public class Page {
                // MARK: Lifecycle

                init(pointer: OpaquePointer) {
                    self.pointer = pointer
                }

                deinit {
                    System.realloc(pointer: UnsafeMutableRawPointer(pointer), size: 0)
                }

                // MARK: Public

                /// Returns a `Font.Glyph` object for character `character` in the page, and returns the glyph’s
                /// `bitmap` and `advance` value.
                public func glyph(for character: UInt32) -> (pageGlyph: Glyph?, bitmap: Bitmap?, advance: Int32) {
                    var advance: Int32 = 0
                    var bitmap: OpaquePointer?
                    let pageGlyph = graphics.getPageGlyph(pointer, character, &bitmap, &advance)
                    return (pageGlyph.map { Glyph(pointer: $0) }, bitmap.map { Bitmap(pointer: $0) }, advance)
                }

                // MARK: Private

                private let pointer: OpaquePointer
            }

            public class Glyph {
                // MARK: Lifecycle

                init(pointer: OpaquePointer) {
                    self.pointer = pointer
                }

                deinit {
                    System.realloc(pointer: UnsafeMutableRawPointer(pointer), size: 0)
                }

                // MARK: Public

                /// Returns the kerning adjustment between characters `character1` and `character2` as specified by the font.
                public func kerning(between character1: UInt32, and character2: UInt32) -> Int32 {
                    graphics.getGlyphKerning(pointer, character1, character2)
                }

                // MARK: Private

                private let pointer: OpaquePointer
            }

            /// Returns the height of the font.
            public var height: UInt8 {
                graphics.getFontHeight(pointer)
            }

            /// Returns the width of the given `text` in the font.
            public func getTextWidth(
                for text: UnsafeRawPointer,
                length: Int,
                encoding: StringEncoding,
                tracking: Int32
            ) -> Int32 {
                graphics.getTextWidth(pointer, text, length, encoding, tracking)
            }

            /// Returns a `Font.Page` object for the given character code. Each font page contains information
            /// for 256 characters; specifically, if `(c1 & ~0xff) == (c2 & ~0xff)`, then `c1` and `c2` belong to the
            /// same page and the same font page can be used to fetch the character data for both instead of searching
            /// for the page twice.
            public func getPage(for character: UInt32) -> Page? {
                graphics.getFontPage(pointer, character).map { Page(pointer: $0) }
            }

            // MARK: Internal

            let pointer: OpaquePointer
        }

        /// The tracking to use when drawing text.
        public static var textTracking: Int32 {
            get { graphics.getTextTracking() }
            set { graphics.setTextTracking(newValue) }
        }

        /// Push a new drawing context for drawing into the given bitmap.
        /// If context is nil, the drawing functions will use the display framebuffer.
        public static func pushContext(_ context: Bitmap?) {
            graphics.pushContext(context?.pointer)
        }

        /// Pops a context off the stack (if any are left), restoring the drawing settings from before the context was pushed.
        public static func popContext() {
            graphics.popContext()
        }

        /// Sets the stencil used for drawing. For a tiled stencil, use setStencilImage() instead.
        /// To clear the stencil, set it to nil.
        public static func setStencil(_ stencil: Bitmap?) {
            graphics.setStencil(stencil?.pointer)
        }

        /// Sets the stencil used for drawing. If `tile` is true the stencil image will be tiled.
        /// Tiled stencils must have width equal to a multiple of 32 pixels.
        /// To clear the stencil, call `setStencil(nil)`.
        public static func setStencilImage(_ stencil: Bitmap, tile: Bool) {
            graphics.setStencilImage(stencil.pointer, tile ? 1 : 0)
        }

        /// Sets the mode used for drawing bitmaps. Note that text drawing uses bitmaps, so this affects how fonts are displayed as well.
        public static func setDrawMode(_ mode: Bitmap.DrawMode) {
            graphics.setDrawMode(mode)
        }

        /// Sets the current clip rect, using world coordinates—​that is, the given rectangle will be translated by
        /// the current drawing offset. The clip rect is cleared at the beginning of each update.
        public static func setClipRect(x: Int32, y: Int32, width: Int32, height: Int32) {
            graphics.setClipRect(x, y, width, height)
        }

        /// Sets the current clip rect in screen coordinates.
        public static func setScreenClipRect(x: Int32, y: Int32, width: Int32, height: Int32) {
            graphics.setScreenClipRect(x, y, width, height)
        }

        /// Clears the current clip rect.
        public static func clearClipRect() {
            graphics.clearClipRect()
        }

        /// Sets the end cap style used in the line drawing functions.
        public static func setLineCapStyle(_ style: LineCapStyle) {
            graphics.setLineCapStyle(style)
        }

        /// Sets the font to use in subsequent drawText calls.
        public static func setFont(_ font: Font) {
            graphics.setFont(font.pointer)
        }

        /// Sets the leading adjustment (added to the leading specified in the font) to use when drawing text.
        public static func setTextLeading(_ leading: Int32) {
            graphics.setTextLeading(leading)
        }

        /// Returns true if any of the opaque pixels in `bitmap1` when positioned at `x1`, `y1` with `flip1` overlap any
        /// of the opaque pixels in `bitmap2` at `x2`, `y2` with `flip2` within the non-empty rect, or false
        /// if no pixels overlap or if one or both fall completely outside of rect.
        public static func checkMaskCollision(
            bitmap1: Bitmap,
            x1: Int32,
            y1: Int32,
            flip1: Bitmap.Flip,
            bitmap2: Bitmap,
            x2: Int32,
            y2: Int32,
            flip2: Bitmap.Flip,
            rect: Rect
        ) -> Bool {
            graphics.checkMaskCollision(bitmap1.pointer, x1, y1, flip1, bitmap2.pointer, x2, y2, flip2, rect) != 0
        }

        /// Draws the `bitmap` with its upper-left corner at location `x`, `y`, using the given `flip` orientation.
        public static func drawBitmap(_ bitmap: Bitmap, x: Int32, y: Int32, flip: Bitmap.Flip) {
            graphics.drawBitmap(bitmap.pointer, x, y, flip)
        }

        /// Draws the `bitmap` scaled to `xScale` and `yScale` with its upper-left corner at location `x`, `y`.
        /// Note that `flip` is not available when drawing scaled bitmaps but negative scale values will achieve the same effect.
        public static func drawBitmap(
            _ bitmap: Bitmap,
            x: Int32,
            y: Int32,
            xScale: Float,
            yScale: Float
        ) {
            graphics.drawScaledBitmap(bitmap.pointer, x, y, xScale, yScale)
        }

        /// Draws the `bitmap` scaled to `xScale` and `yScale` then rotated by `degrees` with its center as given by proportions
        /// `centerX` and `centerY` at `x`, `y`; that is: if `centerX` and `centerY` are both 0.5 the center of the image is at (x,y),
        /// if `centerX` and `centerY` are both 0 the top left corner of the image (before rotation) is at (x,y), etc.
        public static func drawBitmap(
            _ bitmap: Bitmap,
            x: Int32,
            y: Int32,
            degrees: Float,
            centerX: Float,
            centerY: Float,
            xScale: Float,
            yScale: Float
        ) {
            graphics.drawRotatedBitmap(bitmap.pointer, x, y, degrees, centerX, centerY, xScale, yScale)
        }

        /// Draws the `bitmap` with its upper-left corner at location `x`, `y` tiled inside a `width` by `height` rectangle.
        public static func tileBitmap(_ bitmap: Bitmap, x: Int32, y: Int32, width: Int32, height: Int32, flip: Bitmap.Flip) {
            graphics.tileBitmap(bitmap.pointer, x, y, width, height, flip)
        }

        /// Draws the given `text` using the provided options. If no font has been set with `setFont`, the default
        /// system font Asheville Sans 14 Light is used.
        public static func drawText(
            _ text: UnsafeRawPointer?,
            length: Int,
            encoding: StringEncoding,
            x: Int32,
            y: Int32
        ) -> Int32 {
            // TODO: - Figure out what this returns
            graphics.drawText(text, length, encoding, x, y)
        }

        /// Draws an ellipse inside the rectangle {`x`, `y`, `width`, `height`} of width `lineWidth` (inset from the rectangle bounds).
        /// If `startAngle` != `endAngle`, this draws an arc between the given angles. Angles are given in degrees, clockwise from due north.
        public static func drawEllipse(
            x: Int32,
            y: Int32,
            width: Int32,
            height: Int32,
            lineWidth: Int32,
            startAngle: Float,
            endAngle: Float,
            color: Color
        ) {
            graphics.drawEllipse(x, y, width, height, lineWidth, startAngle, endAngle, color)
        }

        /// Fills an ellipse inside the rectangle {`x`, `y`, `width`, `height`}. If `startAngle` != `endAngle`, this draws a
        /// wedge/Pacman between the given angles. Angles are given in degrees, clockwise from due north.
        public static func fillEllipse(
            x: Int32,
            y: Int32,
            width: Int32,
            height: Int32,
            startAngle: Float,
            endAngle: Float,
            color: Color
        ) {
            graphics.fillEllipse(x, y, width, height, startAngle, endAngle, color)
        }

        /// Draws a line from `x1`, `y1` to `x2`, `y2` with a stroke width of `lineWidth`.
        public static func drawLine(x1: Int32, y1: Int32, x2: Int32, y2: Int32, lineWidth: Int32, color: Color) {
            graphics.drawLine(x1, y1, x2, y2, lineWidth, color)
        }

        /// Draws a `width` by `height` rect at `x`, `y`.
        public static func drawRect(x: Int32, y: Int32, width: Int32, height: Int32, color: Color) {
            graphics.drawRect(x, y, width, height, color)
        }

        /// Draws a filled `width` by `height` rect at `x`, `y`.
        public static func fillRect(x: Int32, y: Int32, width: Int32, height: Int32, color: Color) {
            graphics.fillRect(x, y, width, height, color)
        }

        /// Draws a filled triangle with points at `x1`, `y1`, `x2`, `y2`, and `x3`, `y3`.
        public static func fillTriangle(x1: Int32, y1: Int32, x2: Int32, y2: Int32, x3: Int32, y3: Int32, color: Color) {
            graphics.fillTriangle(x1, y1, x2, y2, x3, y3, color)
        }

        /// Fills the polygon with vertices at the given coordinates (an array of 2*nPoints ints containing alternating x and y values)
        /// using the given `color` and fill, or winding, rule. See https://en.wikipedia.org/wiki/Nonzero-rule
        /// for an explanation of the winding rule. An edge between the last vertex and the first is assumed.
        public static func fillPolygon(points: UnsafeMutableBufferPointer<UInt32>, color: Color, fillRule: PolygonFillRule) {
            graphics.fillPolygon(Int32(points.count), points.baseAddress, color, fillRule)
        }

        /// Clears the entire display, filling it with `color`.
        public static func clear(color: Color) {
            graphics.clear(color)
        }

        /// Sets the background color shown when the display is offset or for clearing dirty areas in the sprite system.
        public static func setBackgroundColor(_ color: SolidColor) {
            graphics.setBackgroundColor(color)
        }

        /// Manually flushes the current frame buffer out to the display. This function is automatically called
        /// after each pass through the run loop, so there shouldn’t be any need to call it yourself.
        public static func display() {
            graphics.display()
        }

        /// Only valid in the Simulator; function returns nil on device. Returns the debug framebuffer as a bitmap.
        /// White pixels drawn in the image are overlaid on the display in 50% transparent red.
        public static func getDebugBitmap() -> Bitmap? {
            graphics.getDebugBitmap().map { Bitmap(pointer: $0) }
        }

        /// Returns the raw bits in the display buffer, the last completed frame.
        public static func getDisplayFrame() -> UnsafeMutablePointer<UInt8>? {
            graphics.getDisplayFrame()
        }

        /// Returns a bitmap containing the contents of the display buffer.
        public static func getDisplayBufferBitmap() -> Bitmap? {
            graphics.getDisplayBufferBitmap().map { Bitmap(pointer: $0, free: false) }
        }

        /// Returns the current display frame buffer. Rows are 32-bit aligned, so the row stride is 52 bytes,
        /// with the extra 2 bytes per row ignored. Bytes are MSB-ordered; i.e., the pixel in column 0 is the
        /// 0x80 bit of the first byte of the row.
        public static func getFrame() -> UnsafeMutablePointer<UInt8>? {
            graphics.getFrame()
        }

        /// Returns a copy the contents of the working frame buffer as a bitmap.
        public static func copyFrameBufferBitmap() -> Bitmap? {
            graphics.copyFrameBufferBitmap().map { Bitmap(pointer: $0) }
        }

        /// After updating pixels in the buffer returned by `getFrame()`, you must tell the graphics system which rows were updated.
        /// This function marks a contiguous range of rows as updated (e.g., `markUpdatedRows(0, LCD_ROWS - 1)` tells the system
        /// to update the entire display). Both `start` and `end` are included in the range.
        public static func markUpdatedRows(start: Int32, end: Int32) {
            graphics.markUpdatedRows(start, end)
        }

        /// Offsets the origin point for all drawing calls to `dx`, `dy` (can be negative).
        ///
        /// This is useful, for example, for centering a "camera" on a sprite that is moving around a world larger than the screen.
        public static func setDrawOffset(dx: Int32, dy: Int32) {
            graphics.setDrawOffset(dx, dy)
        }

        /// Returns a color using an 8 x 8 pattern using the given `bitmap`. `x`, `y` indicates the top left corner of the 8 x 8 pattern.
        public static func colorFromPattern(_ pattern: Bitmap, x: Int32, y: Int32) -> Color {
            var color: Color = 0
            graphics.setColorToPattern(&color, pattern.pointer, x, y)
            return color
        }

        // MARK: Private

        private static var graphics: playdate_graphics { playdateAPI.graphics.pointee }
    }
}

public extension Playdate.Graphics.Rect {
    init(x: Int32, y: Int32, width: Int32, height: Int32) {
        self = LCDMakeRect(x, y, width, height)
    }

    func translated(dx: Int32, dy: Int32) -> Playdate.Graphics.Rect {
        LCDRect_translate(self, dx, dy)
    }
}
