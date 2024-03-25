public import CPlaydate

// MARK: - Graphics

/// Functions related to displaying information on the device screen.
public enum Graphics {
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
                pointer = video.loadVideo.unsafelyUnwrapped(path).unsafelyUnwrapped
            }

            deinit { video.freePlayer.unsafelyUnwrapped(pointer) }

            // MARK: Public

            /// Retrieves information about the video.
            public var info: (
                width: CInt, height: CInt,
                frameRate: Float,
                frameCount: CInt, currentFrame: CInt
            ) {
                var width: CInt = 0, height: CInt = 0
                var frameRate: Float = 0
                var frameCount: CInt = 0, currentFrame: CInt = 0
                video.getInfo.unsafelyUnwrapped(
                    pointer,
                    &width,
                    &height,
                    &frameRate,
                    &frameCount,
                    &currentFrame
                )
                return (width, height, frameRate, frameCount, currentFrame)
            }

            /// Gets the rendering destination for the video player. If no rendering context has been set, a context bitmap with the same
            /// dimensions as the vieo will be allocated.
            public var context: Bitmap {
                Bitmap(pointer: video.getContext.unsafelyUnwrapped(pointer).unsafelyUnwrapped)
            }

            /// Sets the rendering destination for the video player to the given bitmap.
            public func setContext(_ context: Bitmap) throws(Playdate.Error) {
                guard video.setContext.unsafelyUnwrapped(pointer, context.pointer) != 0 else {
                    throw error
                }
            }

            /// Sets the rendering destination for the video player to the screen.
            public func useScreenContext() {
                video.useScreenContext.unsafelyUnwrapped(pointer)
            }

            /// Renders frame number `frameNumber` into the current context.
            public func renderFrame(_ frameNumber: CInt) throws(Playdate.Error) {
                guard video.renderFrame.unsafelyUnwrapped(pointer, frameNumber) != 0 else {
                    throw error
                }
            }

            // MARK: Private

            private let pointer: OpaquePointer

            /// Returns the most recent error
            private var error: Playdate.Error {
                Playdate.Error(humanReadableText: video.getError.unsafelyUnwrapped(pointer))
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
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        public init(path: StaticString) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmap(path.utf8Start, &error)
            self.pointer = pointer.unsafelyUnwrapped
            free = true
        }

        /// Allocates and returns a new `Bitmap` from the file at path. If there is no file at `path`, the function throws.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        public init(path: UnsafeMutablePointer<CChar>) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmap.unsafelyUnwrapped(path, &error)
            self.pointer = pointer.unsafelyUnwrapped
            free = true
        }

        /// Allocates and returns a new `width` by `height` `Bitmap` filled with `bgcolor`.
        public init(width: CInt, height: CInt, bgColor: Color) {
            pointer = bgColor.withLCDColor {
                graphics.newBitmap.unsafelyUnwrapped(width, height, $0).unsafelyUnwrapped
            }
            free = true
        }

        deinit {
            if free {
                graphics.freeBitmap.unsafelyUnwrapped(pointer)
            }
        }

        // MARK: Public

        public typealias DrawMode = LCDBitmapDrawMode
        public typealias Flip = LCDBitmapFlip

        /// Gets/sets a `mask` image for the bitmap, or returns nil if the bitmap doesn’t have a mask layer.
        /// The set mask must be the same size as the target bitmap. The returned mask points to bitmap's data,
        /// so drawing into the mask image affects the source bitmap directly.
        public var mask: Bitmap? {
            didSet {
                _ = graphics.setBitmapMask.unsafelyUnwrapped(pointer, mask?.pointer)
            }
        }

        /// Loads the image at `path` into the bitmap.
        public func load(from path: StaticString) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmap(path.utf8Start, pointer, &error)
            if let error { throw Playdate.Error(humanReadableText: error) }
        }

        /// Loads the image at `path` into the bitmap.
        public func load(from path: UnsafeMutablePointer<CChar>) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmap.unsafelyUnwrapped(path, pointer, &error)
            if let error { throw Playdate.Error(humanReadableText: error) }
        }

        /// Clears the bitmap, filling with the given `bgcolor`.
        public func clear(bgColor: Color) {
            bgColor.withLCDColor {
                graphics.clearBitmap.unsafelyUnwrapped(pointer, $0)
            }
        }

        /// Returns a new LCDBitmap that is an exact copy of the bitmap.
        public func copy() -> Bitmap {
            let bitmap = graphics.copyBitmap.unsafelyUnwrapped(pointer).unsafelyUnwrapped
            return Bitmap(pointer: bitmap)
        }

        /// Gets various info about the bitmap including its `width` and `height` and raw pixel `data`.
        /// The data is 1 bit per pixel packed format, in MSB order; in other words, the high bit of the first byte
        /// in data is the top left pixel of the image. If the bitmap has a mask, a pointer to its data is returned in `mask`,
        /// else nil is returned.
        public func getData(
            mask: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?,
            data: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?
        ) -> (
            width: CInt, height: CInt, rowBytes: CInt
        ) {
            var width: CInt = 0, height: CInt = 0, rowBytes: CInt = 0
            graphics.getBitmapData.unsafelyUnwrapped(pointer, &width, &height, &rowBytes, mask, data)
            return (width, height, rowBytes)
        }

        /// Returns a new, rotated and scaled `Bitmap` based on the given `bitmap`.
        public func rotated(by rotation: Float, xScale: Float, yScale: Float) -> (
            bitmap: Bitmap,
            allocatedSize: CInt
        ) {
            var allocatedSize: CInt = 0
            let bitmap = graphics.rotatedBitmap.unsafelyUnwrapped(pointer, rotation, xScale, yScale, &allocatedSize).unsafelyUnwrapped
            return (Bitmap(pointer: bitmap), allocatedSize)
        }

        // MARK: Internal

        let pointer: OpaquePointer

        // MARK: Private

        private let free: Bool
    }

    /// A solid color or pattern.
    public enum Color {
        case solid(SolidColor)
        /// A pattern color, where `bitmap` is an 8x8 bitmap pattern and `mask` is an 8x8 alpha mask.
        case pattern(
            _ bitmap: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8),
            mask: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (
                UInt8.max, UInt8.max, UInt8.max, UInt8.max, UInt8.max, UInt8.max, UInt8.max, UInt8.max
            )
        )

        // MARK: Public

        public nonisolated(unsafe) static let black = Color.solid(.black)
        public nonisolated(unsafe) static let white = Color.solid(.white)
        public nonisolated(unsafe) static let clear = Color.solid(.clear)
        public nonisolated(unsafe) static let xor = Color.solid(.xor)

        // MARK: Internal

        func withLCDColor<T>(_ body: (LCDColor) throws -> T) rethrows -> T {
            switch self {
            case let .solid(solidColor):
                return try body(LCDColor(solidColor.rawValue))
            case let .pattern(bitmap, mask):
                let pattern = LCDPattern((
                    bitmap.0, bitmap.1, bitmap.2, bitmap.3, bitmap.4, bitmap.5, bitmap.6, bitmap.7,
                    mask.0, mask.1, mask.2, mask.3, mask.4, mask.5, mask.6, mask.7
                ))
                return try withUnsafeBytes(of: pattern) {
                    try body(LCDColor(bitPattern: $0.baseAddress))
                }
            }
        }
    }

    public typealias LineCapStyle = LCDLineCapStyle
    public typealias StringEncoding = PDStringEncoding
    public typealias PolygonFillRule = LCDPolygonFillRule
    public typealias SolidColor = LCDSolidColor

    public class BitmapTable {
        // MARK: Lifecycle

        /// Allocates and returns a new `BitmapTable` from the file at `path`. If there is no file at `path`, the function throws an error.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        public init(path: StaticString) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmapTable(path.utf8Start, &error)
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Allocates and returns a new `BitmapTable` from the file at `path`. If there is no file at `path`, the function throws an error.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        public init(path: UnsafeMutablePointer<CChar>) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmapTable.unsafelyUnwrapped(path, &error)
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Allocates and returns a new `BitmapTable` that can hold `count` `width` by `height` `Bitmaps`.
        public init(count: CInt, width: CInt, height: CInt) {
            pointer = graphics.newBitmapTable.unsafelyUnwrapped(count, width, height).unsafelyUnwrapped
        }

        deinit { graphics.freeBitmapTable(pointer) }

        // MARK: Public

        /// Returns the `index` bitmap in `table`, If `index` is out of bounds, the function returns nil.
        public func bitmap(at index: CInt) -> Bitmap? {
            graphics.getTableBitmap.unsafelyUnwrapped(pointer, index).map { Bitmap(pointer: $0) }
        }

        /// Loads the image table at `path` into the previously allocated `table`.
        public func load(from path: StaticString) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmapTable(path.utf8Start, pointer, &error)
            if let error { throw Playdate.Error(humanReadableText: error) }
        }

        /// Loads the image table at `path` into the previously allocated `table`.
        public func load(from path: UnsafeMutablePointer<CChar>) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmapTable.unsafelyUnwrapped(path, pointer, &error)
            if let error { throw Playdate.Error(humanReadableText: error) }
        }

        // MARK: Private

        private let pointer: OpaquePointer
    }

    public class Font {
        // MARK: Lifecycle

        /// Returns a `Font` object for the font file at `path`.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        init(path: StaticString) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadFont(path.utf8Start, &error)
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Returns a `Font` object for the font file at `path`.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        init(path: UnsafeMutablePointer<CChar>) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadFont.unsafelyUnwrapped(path, &error)
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Returns a `Font` object wrapping the `LCDFontData` `data` comprising the contents (minus 16-byte header)
        /// of an uncompressed pft file. `wide` corresponds to the flag in the header indicating whether the font contains
        /// glyphs at codepoints above U+1FFFF.
        /// > Warning: Currently unsafe due to https://github.com/finnvoor/PlaydateKit/issues/7
        init(data: OpaquePointer, wide: Bool) {
            let pointer = graphics.makeFontFromData.unsafelyUnwrapped(data, wide ? 1 : 0)
            self.pointer = pointer.unsafelyUnwrapped
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
            public func glyph(for character: CUnsignedInt) -> (
                pageGlyph: Glyph?,
                bitmap: Bitmap?,
                advance: CInt
            ) {
                var advance: CInt = 0
                var bitmap: OpaquePointer?
                let pageGlyph = graphics.getPageGlyph.unsafelyUnwrapped(
                    pointer,
                    character,
                    &bitmap,
                    &advance
                )
                return (
                    pageGlyph.map { Glyph(pointer: $0) },
                    bitmap.map { Bitmap(pointer: $0) },
                    advance
                )
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
            public func kerning(between character1: CUnsignedInt, and character2: CUnsignedInt) -> CInt {
                graphics.getGlyphKerning.unsafelyUnwrapped(pointer, character1, character2)
            }

            // MARK: Private

            private let pointer: OpaquePointer
        }

        /// Returns the height of the font.
        public var height: UInt8 {
            graphics.getFontHeight.unsafelyUnwrapped(pointer)
        }

        /// Returns the width of the given `text` in the font.
        public func getTextWidth(
            for text: StaticString,
            tracking: CInt
        ) -> CInt {
            graphics.getTextWidth.unsafelyUnwrapped(
                pointer,
                text.utf8Start,
                text.utf8CodeUnitCount,
                .kUTF8Encoding,
                tracking
            )
        }

        /// Returns the width of the given `text` in the font.
        public func getTextWidth(
            for text: UnsafeRawPointer,
            length: Int,
            encoding: StringEncoding,
            tracking: CInt
        ) -> CInt {
            graphics.getTextWidth.unsafelyUnwrapped(pointer, text, length, encoding, tracking)
        }

        /// Returns a `Font.Page` object for the given character code. Each font page contains information
        /// for 256 characters; specifically, if `(c1 & ~0xff) == (c2 & ~0xff)`, then `c1` and `c2` belong to the
        /// same page and the same font page can be used to fetch the character data for both instead of searching
        /// for the page twice.
        public func getPage(for character: CUnsignedInt) -> Page? {
            graphics.getFontPage.unsafelyUnwrapped(pointer, character).map { Page(pointer: $0) }
        }

        // MARK: Internal

        let pointer: OpaquePointer
    }

    /// The tracking to use when drawing text.
    public static var textTracking: CInt {
        get { graphics.getTextTracking.unsafelyUnwrapped() }
        set { graphics.setTextTracking.unsafelyUnwrapped(newValue) }
    }

    /// The mode used for drawing bitmaps. Note that text drawing uses bitmaps, so this affects how fonts are displayed as well.
    public nonisolated(unsafe) static var drawMode: Bitmap.DrawMode = .copy {
        didSet {
            graphics.setDrawMode.unsafelyUnwrapped(drawMode)
        }
    }

    /// Push a new drawing context for drawing into the given bitmap.
    /// If context is nil, the drawing functions will use the display framebuffer.
    public static func pushContext(_ context: Bitmap?) {
        graphics.pushContext.unsafelyUnwrapped(context?.pointer)
    }

    /// Pops a context off the stack (if any are left), restoring the drawing settings from before the context was pushed.
    public static func popContext() {
        graphics.popContext.unsafelyUnwrapped()
    }

    /// Sets the stencil used for drawing. For a tiled stencil, use setStencilImage() instead.
    /// To clear the stencil, set it to nil.
    public static func setStencil(_ stencil: Bitmap?) {
        graphics.setStencil.unsafelyUnwrapped(stencil?.pointer)
    }

    /// Sets the stencil used for drawing. If `tile` is true the stencil image will be tiled.
    /// Tiled stencils must have width equal to a multiple of 32 pixels.
    /// To clear the stencil, call `setStencil(nil)`.
    public static func setStencilImage(_ stencil: Bitmap, tile: Bool) {
        graphics.setStencilImage.unsafelyUnwrapped(stencil.pointer, tile ? 1 : 0)
    }

    /// Sets the current clip rect, using world coordinates—​that is, the given rectangle will be translated by
    /// the current drawing offset. The clip rect is cleared at the beginning of each update.
    public static func setClipRect(_ rect: Rect<CInt>) {
        graphics.setClipRect.unsafelyUnwrapped(rect.x, rect.y, rect.width, rect.height)
    }

    /// Sets the current clip rect in screen coordinates.
    public static func setScreenClipRect(_ rect: Rect<CInt>) {
        graphics.setScreenClipRect.unsafelyUnwrapped(rect.x, rect.y, rect.width, rect.height)
    }

    /// Clears the current clip rect.
    public static func clearClipRect() {
        graphics.clearClipRect.unsafelyUnwrapped()
    }

    /// Sets the end cap style used in the line drawing functions.
    public static func setLineCapStyle(_ style: LineCapStyle) {
        graphics.setLineCapStyle.unsafelyUnwrapped(style)
    }

    /// Sets the font to use in subsequent drawText calls.
    public static func setFont(_ font: Font) {
        graphics.setFont.unsafelyUnwrapped(font.pointer)
    }

    /// Sets the leading adjustment (added to the leading specified in the font) to use when drawing text.
    public static func setTextLeading(_ leading: CInt) {
        graphics.setTextLeading.unsafelyUnwrapped(leading)
    }

    /// Returns true if any of the opaque pixels in `bitmap1` when positioned at `point1` with `flip1` overlap any
    /// of the opaque pixels in `bitmap2` at `point2` with `flip2` within the non-empty rect, or false
    /// if no pixels overlap or if one or both fall completely outside of rect.
    public static func checkMaskCollision(
        bitmap1: Bitmap,
        point1: Point<CInt>,
        flip1: Bitmap.Flip,
        bitmap2: Bitmap,
        point2: Point<CInt>,
        flip2: Bitmap.Flip,
        rect: Rect<CInt>
    ) -> Bool {
        graphics.checkMaskCollision.unsafelyUnwrapped(
            bitmap1.pointer,
            point1.x,
            point1.y,
            flip1,
            bitmap2.pointer,
            point2.x,
            point2.y,
            flip2,
            rect.lcdRect
        ) != 0
    }

    /// Draws the `bitmap` with its upper-left corner at location `point`, using the given `flip` orientation.
    public static func drawBitmap(_ bitmap: Bitmap, at point: Point<CInt>, flip: Bitmap.Flip) {
        graphics.drawBitmap.unsafelyUnwrapped(bitmap.pointer, point.x, point.y, flip)
    }

    /// Draws the `bitmap` scaled to `xScale` and `yScale` with its upper-left corner at location `point`.
    /// Note that `flip` is not available when drawing scaled bitmaps but negative scale values will achieve the same effect.
    public static func drawBitmap(
        _ bitmap: Bitmap,
        at point: Point<CInt>,
        xScale: Float = 1,
        yScale: Float = 1
    ) {
        graphics.drawScaledBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            point.x,
            point.y,
            xScale,
            yScale
        )
    }

    /// Draws the `bitmap` scaled to `xScale` and `yScale` then rotated by `degrees` with its center as given by proportions
    /// `center` at `point`; that is: if `center` is (0.5, 0.5) the center of the image is at (point.x, point.y),
    /// if `center` is (0, 0) the top left corner of the image (before rotation) is at (point.x, point.y), etc.
    public static func drawBitmap(
        _ bitmap: Bitmap,
        at point: Point<CInt>,
        degrees: Float,
        center: Point<Float>,
        xScale: Float = 1,
        yScale: Float = 1
    ) {
        graphics.drawRotatedBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            point.x,
            point.y,
            degrees,
            center.x,
            center.y,
            xScale,
            yScale
        )
    }

    /// Draws the `bitmap` tiled inside `rect`.
    public static func tileBitmap(
        _ bitmap: Bitmap,
        inside rect: Rect<CInt>,
        flip: Bitmap.Flip
    ) {
        graphics.tileBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            rect.x,
            rect.y,
            rect.width,
            rect.height,
            flip
        )
    }

    /// Draws the given `text`. If no font has been set with `setFont`, the default
    /// system font Asheville Sans 14 Light is used.
    ///
    /// Returns the drawn width of the given `text`.
    @discardableResult public static func drawText(
        _ text: StaticString,
        at point: Point<CInt>
    ) -> CInt {
        graphics.drawText.unsafelyUnwrapped(
            text.utf8Start,
            text.utf8CodeUnitCount,
            .kUTF8Encoding,
            point.x,
            point.y
        )
    }

    /// Draws the given `text` using the provided options. If no font has been set with `setFont`, the default
    /// system font Asheville Sans 14 Light is used.
    ///
    /// Returns the drawn width of the given `text`.
    @discardableResult public static func drawText(
        _ text: UnsafeRawPointer?,
        length: Int,
        encoding: StringEncoding,
        at point: Point<CInt>
    ) -> CInt {
        graphics.drawText.unsafelyUnwrapped(text, length, encoding, point.x, point.y)
    }

    /// Draws an ellipse inside the rectangle `rect` of width `lineWidth` (inset from the rectangle bounds).
    /// If `startAngle` != `endAngle`, this draws an arc between the given angles.
    /// Angles are given in degrees, clockwise from due north.
    public static func drawEllipse(
        in rect: Rect<CInt>,
        lineWidth: CInt = 1,
        startAngle: Float = 0,
        endAngle: Float = 360,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawEllipse.unsafelyUnwrapped(
                rect.x,
                rect.y,
                rect.width,
                rect.height,
                lineWidth,
                startAngle,
                endAngle,
                $0
            )
        }
    }

    /// Fills an ellipse inside the rectangle `rect`. If `startAngle` != `endAngle`, this draws a
    /// wedge/Pacman between the given angles. Angles are given in degrees, clockwise from due north.
    public static func fillEllipse(
        in rect: Rect<CInt>,
        startAngle: Float = 0,
        endAngle: Float = 360,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillEllipse.unsafelyUnwrapped(
                rect.x,
                rect.y,
                rect.width,
                rect.height,
                startAngle,
                endAngle,
                $0
            )
        }
    }

    /// Draws `line` with a stroke width of `lineWidth` and color `color`.
    public static func drawLine(
        _ line: Line<CInt>,
        lineWidth: CInt = 1,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawLine.unsafelyUnwrapped(
                line.start.x,
                line.start.y,
                line.end.x,
                line.end.y,
                lineWidth,
                $0
            )
        }
    }

    /// Draws a `rect` with the specified `color`.
    public static func drawRect(
        _ rect: Rect<CInt>,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawRect.unsafelyUnwrapped(rect.x, rect.y, rect.width, rect.height, $0)
        }
    }

    /// Draws a `rect` filled with the specified `color`
    public static func fillRect(
        _ rect: Rect<CInt>,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillRect.unsafelyUnwrapped(
                rect.x,
                rect.y,
                rect.width,
                rect.height,
                $0
            )
        }
    }

    /// Draws a filled triangle with points at `p1`, `p2`, and `p3`.
    public static func fillTriangle(
        p1: Point<CInt>,
        p2: Point<CInt>,
        p3: Point<CInt>,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillTriangle.unsafelyUnwrapped(
                p1.x,
                p1.y,
                p2.x,
                p2.y,
                p3.x,
                p3.y,
                $0
            )
        }
    }

    /// Fills the polygon with vertices at the given coordinates (an array of `points`)
    /// using the given `color` and fill, or winding, rule. See https://en.wikipedia.org/wiki/Nonzero-rule
    /// for an explanation of the winding rule. An edge between the last vertex and the first is assumed.
    public static func fillPolygon(
        points: [Point<CInt>],
        color: Color = .black,
        fillRule: PolygonFillRule
    ) {
        color.withLCDColor {
            var points = points.flatMap { [$0.x, $0.y] }
            graphics.fillPolygon.unsafelyUnwrapped(CInt(points.count), &points, $0, fillRule)
        }
    }

    /// Clears the entire display, filling it with `color`.
    public static func clear(color: Color = .clear) {
        color.withLCDColor {
            graphics.clear.unsafelyUnwrapped($0)
        }
    }

    /// Sets the background color shown when the display is offset or for clearing dirty areas in the sprite system.
    public static func setBackgroundColor(_ color: SolidColor) {
        graphics.setBackgroundColor.unsafelyUnwrapped(color)
    }

    /// Manually flushes the current frame buffer out to the display. This function is automatically called
    /// after each pass through the run loop, so there shouldn’t be any need to call it yourself.
    public static func display() {
        graphics.display.unsafelyUnwrapped()
    }

    /// Only valid in the Simulator; function returns nil on device. Returns the debug framebuffer as a bitmap.
    /// White pixels drawn in the image are overlaid on the display in 50% transparent red.
    public static func getDebugBitmap() -> Bitmap? {
        graphics.getDebugBitmap.unsafelyUnwrapped().map { Bitmap(pointer: $0) }
    }

    /// Returns the raw bits in the display buffer, the last completed frame.
    public static func getDisplayFrame() -> UnsafeMutablePointer<UInt8>? {
        graphics.getDisplayFrame.unsafelyUnwrapped()
    }

    /// Returns a bitmap containing the contents of the display buffer.
    public static func getDisplayBufferBitmap() -> Bitmap? {
        graphics.getDisplayBufferBitmap.unsafelyUnwrapped().map { Bitmap(pointer: $0, free: false) }
    }

    /// Returns the current display frame buffer. Rows are 32-bit aligned, so the row stride is 52 bytes,
    /// with the extra 2 bytes per row ignored. Bytes are MSB-ordered; i.e., the pixel in column 0 is the
    /// 0x80 bit of the first byte of the row.
    public static func getFrame() -> UnsafeMutablePointer<UInt8>? {
        graphics.getFrame.unsafelyUnwrapped()
    }

    /// Returns a copy the contents of the working frame buffer as a bitmap.
    public static func copyFrameBufferBitmap() -> Bitmap? {
        graphics.copyFrameBufferBitmap.unsafelyUnwrapped().map { Bitmap(pointer: $0) }
    }

    /// After updating pixels in the buffer returned by `getFrame()`, you must tell the graphics system which rows were updated.
    /// This function marks a contiguous range of rows as updated (e.g., `markUpdatedRows(0, LCD_ROWS - 1)` tells the system
    /// to update the entire display). Both `start` and `end` are included in the range.
    public static func markUpdatedRows(start: CInt, end: CInt) {
        graphics.markUpdatedRows.unsafelyUnwrapped(start, end)
    }

    /// Offsets the origin point for all drawing calls to `dx`, `dy` (can be negative).
    ///
    /// This is useful, for example, for centering a "camera" on a sprite that is moving around a world larger than the screen.
    public static func setDrawOffset(dx: CInt, dy: CInt) {
        graphics.setDrawOffset.unsafelyUnwrapped(dx, dy)
    }

    /// Returns a color using an 8 x 8 pattern using the given `bitmap`. `topLeft` indicates the top left corner of the 8 x 8 pattern.
    public static func colorFromPattern(_ pattern: Bitmap, topLeft: Point<CInt> = .zero) -> LCDColor {
        var color: LCDColor = 0
        graphics.setColorToPattern.unsafelyUnwrapped(&color, pattern.pointer, topLeft.x, topLeft.y)
        return color
    }

    // MARK: Private

    private static var graphics: playdate_graphics { Playdate.playdateAPI.graphics.pointee }
}
