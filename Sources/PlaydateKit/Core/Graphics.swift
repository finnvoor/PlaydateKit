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
            public init(path: String) {
                pointer = video.loadVideo.unsafelyUnwrapped(path).unsafelyUnwrapped
            }

            deinit { video.freePlayer.unsafelyUnwrapped(pointer) }

            // MARK: Public

            /// Retrieves information about the video.
            public var info: (
                width: Int, height: Int,
                frameRate: Float,
                frameCount: Int, currentFrame: Int
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
                return (Int(width), Int(height), frameRate, Int(frameCount), Int(currentFrame))
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
            public func renderFrame(_ frameNumber: Int) throws(Playdate.Error) {
                guard video.renderFrame.unsafelyUnwrapped(pointer, CInt(frameNumber)) != 0 else {
                    throw error
                }
            }

            // MARK: Private

            private let pointer: OpaquePointer

            /// Returns the most recent error
            private var error: Playdate.Error {
                Playdate.Error(
                    description: String(cString: video.getError.unsafelyUnwrapped(pointer)!)
                )
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
        public init(path: String) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmap.unsafelyUnwrapped(path, &error)
            if let error { throw Playdate.Error(description: String(cString: error)) }
            self.pointer = pointer.unsafelyUnwrapped
            free = true
        }

        /// Allocates and returns a new `width` by `height` `Bitmap` filled with `bgcolor`.
        public init(width: Int, height: Int, bgColor: Color = .clear) {
            pointer = bgColor.withLCDColor {
                graphics.newBitmap.unsafelyUnwrapped(CInt(width), CInt(height), $0).unsafelyUnwrapped
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
        public func load(from path: String) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmap.unsafelyUnwrapped(path, pointer, &error)
            if let error { throw Playdate.Error(description: String(cString: error)) }
        }

        /// Clears the bitmap, filling with the given `bgcolor`.
        public func clear(bgColor: Color = .clear) {
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
            width: Int, height: Int, rowBytes: Int
        ) {
            var width: CInt = 0, height: CInt = 0, rowBytes: CInt = 0
            graphics.getBitmapData.unsafelyUnwrapped(pointer, &width, &height, &rowBytes, mask, data)
            return (Int(width), Int(height), Int(rowBytes))
        }

        /// Gets the color of the pixel at `point` in the bitmap. If the coordinate is outside the bounds
        /// of the bitmap, or if the bitmap has a mask and the pixel is marked transparent, the function
        /// returns clear; otherwise the return value is white or black.
        public func getPixel(at point: Point) -> Color {
            .solid(graphics.getBitmapPixel(pointer, CInt(point.x), CInt(point.y)))
        }

        /// Returns a new, rotated and scaled `Bitmap` based on the given `bitmap`.
        public func rotated(by rotation: Float, xScale: Float, yScale: Float) -> (
            bitmap: Bitmap,
            allocatedSize: Int
        ) {
            var allocatedSize: CInt = 0
            let bitmap = graphics.rotatedBitmap.unsafelyUnwrapped(pointer, rotation, xScale, yScale, &allocatedSize).unsafelyUnwrapped
            return (Bitmap(pointer: bitmap), Int(allocatedSize))
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
    
    public typealias TextWrap = PDTextWrappingMode

    public class BitmapTable {
        // MARK: Lifecycle

        /// Allocates and returns a new `BitmapTable` from the file at `path`. If there is no file at `path`, the function throws an error.
        public init(path: String) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadBitmapTable.unsafelyUnwrapped(path, &error)
            if let error { throw Playdate.Error(description: String(cString: error)) }
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Allocates and returns a new `BitmapTable` that can hold `count` `width` by `height` `Bitmaps`.
        public init(count: Int, width: Int, height: Int) {
            pointer = graphics.newBitmapTable.unsafelyUnwrapped(
                CInt(count),
                CInt(width),
                CInt(height)
            ).unsafelyUnwrapped
        }

        deinit { graphics.freeBitmapTable(pointer) }

        // MARK: Public

        /// The table's image count.
        public var imageCount: Int {
            var count: CInt = 0
            graphics.getBitmapTableInfo.unsafelyUnwrapped(pointer, &count, nil)
            return Int(count)
        }

        /// The number of cells across.
        public var cellsWide: Int {
            var cellsWide: CInt = 0
            graphics.getBitmapTableInfo.unsafelyUnwrapped(pointer, nil, &cellsWide)
            return Int(cellsWide)
        }

        /// Returns the `index` bitmap in `table`, If `index` is out of bounds, the function returns nil.
        public func bitmap(at index: Int) -> Bitmap? {
            graphics.getTableBitmap.unsafelyUnwrapped(pointer, CInt(index)).map { Bitmap(pointer: $0) }
        }

        public subscript(_ index: Int) -> Bitmap? {
            bitmap(at: index)
        }

        /// Loads the image table at `path` into the previously allocated `table`.
        public func load(from path: String) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmapTable.unsafelyUnwrapped(path, pointer, &error)
            if let error { throw Playdate.Error(description: String(cString: error)) }
        }

        // MARK: Private

        private let pointer: OpaquePointer
    }

    public class Font {
        // MARK: Lifecycle

        /// Returns a `Font` object for the font file at `path`.
        public init(path: String) throws(Playdate.Error) {
            var error: UnsafePointer<CChar>?
            let pointer = graphics.loadFont.unsafelyUnwrapped(path, &error)
            if let error { throw Playdate.Error(description: String(cString: error)) }
            self.pointer = pointer.unsafelyUnwrapped
        }

        /// Returns a `Font` object wrapping the `LCDFontData` `data` comprising the contents (minus 16-byte header)
        /// of an uncompressed pft file. `wide` corresponds to the flag in the header indicating whether the font contains
        /// glyphs at codepoints above U+1FFFF.
        public init?(data: OpaquePointer, wide: Bool) {
            guard let pointer = graphics.makeFontFromData.unsafelyUnwrapped(data, wide ? 1 : 0) else {
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
            public func glyph(for character: CUnsignedInt) -> (
                pageGlyph: Glyph?,
                bitmap: Bitmap?,
                advance: Int
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
                    Int(advance)
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
            public func kerning(between character1: CUnsignedInt, and character2: CUnsignedInt) -> Int {
                Int(graphics.getGlyphKerning.unsafelyUnwrapped(pointer, character1, character2))
            }

            // MARK: Private

            private let pointer: OpaquePointer
        }

        /// Returns the height of the font.
        public var height: Int {
            Int(graphics.getFontHeight.unsafelyUnwrapped(pointer))
        }

        /// Returns the width of the given `text` in the font.
        public func getTextWidth(
            for text: String,
            tracking: Int
        ) -> Int {
            Int(graphics.getTextWidth.unsafelyUnwrapped(
                pointer,
                text,
                text.utf8.count,
                .kUTF8Encoding,
                CInt(tracking)
            ))
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
    public static var textTracking: Int {
        get { Int(graphics.getTextTracking.unsafelyUnwrapped()) }
        set { graphics.setTextTracking.unsafelyUnwrapped(CInt(newValue)) }
    }

    /// The mode used for drawing bitmaps. Note that text drawing uses bitmaps, so this affects how fonts are displayed as well.
    public nonisolated(unsafe) static var drawMode: Bitmap.DrawMode = .copy {
        didSet {
            _ = graphics.setDrawMode.unsafelyUnwrapped(drawMode)
        }
    }

    /// Push a new drawing context for drawing into the given bitmap.
    /// If context is nil, the drawing functions will use the display framebuffer.
    public static func pushContext(_ context: Bitmap? = nil) {
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
    public static func setClipRect(_ rect: Rect) {
        graphics.setClipRect.unsafelyUnwrapped(
            CInt(rect.x),
            CInt(rect.y),
            CInt(rect.width),
            CInt(rect.height)
        )
    }

    /// Sets the current clip rect in screen coordinates.
    public static func setScreenClipRect(_ rect: Rect) {
        graphics.setScreenClipRect.unsafelyUnwrapped(
            CInt(rect.x),
            CInt(rect.y),
            CInt(rect.width),
            CInt(rect.height)
        )
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
    public static func setTextLeading(_ leading: Int) {
        graphics.setTextLeading.unsafelyUnwrapped(CInt(leading))
    }

    /// Returns true if any of the opaque pixels in `bitmap1` when positioned at `point1` with `flip1` overlap any
    /// of the opaque pixels in `bitmap2` at `point2` with `flip2` within the non-empty rect, or false
    /// if no pixels overlap or if one or both fall completely outside of rect.
    public static func checkMaskCollision(
        bitmap1: Bitmap,
        point1: Point,
        flip1: Bitmap.Flip,
        bitmap2: Bitmap,
        point2: Point,
        flip2: Bitmap.Flip,
        rect: Rect
    ) -> Bool {
        graphics.checkMaskCollision.unsafelyUnwrapped(
            bitmap1.pointer,
            CInt(point1.x),
            CInt(point1.y),
            flip1,
            bitmap2.pointer,
            CInt(point2.x),
            CInt(point2.y),
            flip2,
            rect.lcdRect
        ) != 0
    }

    /// Draws the `bitmap` with its upper-left corner at location `point`, using the given `flip` orientation.
    public static func drawBitmap(
        _ bitmap: Bitmap,
        at point: Point = .zero,
        flip: Bitmap.Flip = .unflipped
    ) {
        graphics.drawBitmap.unsafelyUnwrapped(bitmap.pointer, CInt(point.x), CInt(point.y), flip)
    }

    /// Draws the `bitmap` scaled to `xScale` and `yScale` with its upper-left corner at location `point`.
    /// Note that `flip` is not available when drawing scaled bitmaps but negative scale values will achieve the same effect.
    public static func drawBitmap(
        _ bitmap: Bitmap,
        at point: Point,
        xScale: Float = 1,
        yScale: Float = 1
    ) {
        graphics.drawScaledBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            CInt(point.x),
            CInt(point.y),
            xScale,
            yScale
        )
    }

    /// Draws the `bitmap` scaled to `xScale` and `yScale` then rotated by `degrees` with its center as given by proportions
    /// `center` at `point`; that is: if `center` is (0.5, 0.5) the center of the image is at (point.x, point.y),
    /// if `center` is (0, 0) the top left corner of the image (before rotation) is at (point.x, point.y), etc.
    public static func drawBitmap(
        _ bitmap: Bitmap,
        at point: Point,
        degrees: Float,
        center: Point,
        xScale: Float = 1,
        yScale: Float = 1
    ) {
        graphics.drawRotatedBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            CInt(point.x),
            CInt(point.y),
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
        inside rect: Rect,
        flip: Bitmap.Flip
    ) {
        graphics.tileBitmap.unsafelyUnwrapped(
            bitmap.pointer,
            CInt(rect.x),
            CInt(rect.y),
            CInt(rect.width),
            CInt(rect.height),
            flip
        )
    }

    /// Draws the given `text`. If no font has been set with `setFont`, the default
    /// system font Asheville Sans 14 Light is used.
    ///
    /// Returns the drawn width of the given `text`.
    @discardableResult public static func drawText(
        _ text: String,
        at point: Point
    ) -> Int {
        Int(graphics.drawText.unsafelyUnwrapped(
            text,
            text.utf8.count,
            .kUTF8Encoding,
            CInt(point.x),
            CInt(point.y)
        ))
    }

    /// Draws an ellipse inside the rectangle `rect` of width `lineWidth` (inset from the rectangle bounds).
    /// If `startAngle` != `endAngle`, this draws an arc between the given angles.
    /// Angles are given in degrees, clockwise from due north.
    public static func drawEllipse(
        in rect: Rect,
        lineWidth: Int = 1,
        startAngle: Float = 0,
        endAngle: Float = 360,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawEllipse.unsafelyUnwrapped(
                CInt(rect.x),
                CInt(rect.y),
                CInt(rect.width),
                CInt(rect.height),
                CInt(lineWidth),
                startAngle,
                endAngle,
                $0
            )
        }
    }

    /// Fills an ellipse inside the rectangle `rect`. If `startAngle` != `endAngle`, this draws a
    /// wedge/Pacman between the given angles. Angles are given in degrees, clockwise from due north.
    public static func fillEllipse(
        in rect: Rect,
        startAngle: Float = 0,
        endAngle: Float = 360,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillEllipse.unsafelyUnwrapped(
                CInt(rect.x),
                CInt(rect.y),
                CInt(rect.width),
                CInt(rect.height),
                startAngle,
                endAngle,
                $0
            )
        }
    }

    /// Draws `line` with a stroke width of `lineWidth` and color `color`.
    public static func drawLine(
        _ line: Line,
        lineWidth: Int = 1,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawLine.unsafelyUnwrapped(
                CInt(line.start.x),
                CInt(line.start.y),
                CInt(line.end.x),
                CInt(line.end.y),
                CInt(lineWidth),
                $0
            )
        }
    }

    /// Draws a `rect` with the specified `color`.
    public static func drawRect(
        _ rect: Rect,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.drawRect.unsafelyUnwrapped(
                CInt(rect.x),
                CInt(rect.y),
                CInt(rect.width),
                CInt(rect.height),
                $0
            )
        }
    }

    /// Draws a `rect` filled with the specified `color`
    public static func fillRect(
        _ rect: Rect,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillRect.unsafelyUnwrapped(
                CInt(rect.x),
                CInt(rect.y),
                CInt(rect.width),
                CInt(rect.height),
                $0
            )
        }
    }

    /// Draws a filled triangle with points at `p1`, `p2`, and `p3`.
    public static func fillTriangle(
        p1: Point,
        p2: Point,
        p3: Point,
        color: Color = .black
    ) {
        color.withLCDColor {
            graphics.fillTriangle.unsafelyUnwrapped(
                CInt(p1.x),
                CInt(p1.y),
                CInt(p2.x),
                CInt(p2.y),
                CInt(p3.x),
                CInt(p3.y),
                $0
            )
        }
    }

    /// Fills the specified polygon using the given `color` and fill, or winding, rule.
    /// See https://en.wikipedia.org/wiki/Nonzero-rule for an explanation of the winding rule.
    /// An edge between the last vertex and the first is assumed.
    public static func fillPolygon(
        _ polygon: Polygon,
        color: Color = .black,
        fillRule: PolygonFillRule
    ) {
        color.withLCDColor {
            var points = polygon.vertices.flatMap { [CInt($0.x), CInt($0.y)] }
            graphics.fillPolygon.unsafelyUnwrapped(CInt(points.count / 2), &points, $0, fillRule)
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
    public static func markUpdatedRows(start: Int, end: Int) {
        graphics.markUpdatedRows.unsafelyUnwrapped(CInt(start), CInt(end))
    }

    /// Offsets the origin point for all drawing calls to `dx`, `dy` (can be negative).
    ///
    /// This is useful, for example, for centering a "camera" on a sprite that is moving around a world larger than the screen.
    public static func setDrawOffset(dx: Int, dy: Int) {
        graphics.setDrawOffset.unsafelyUnwrapped(CInt(dx), CInt(dy))
    }

    /// Returns a color using an 8 x 8 pattern using the given `bitmap`. `topLeft` indicates the top left corner of the 8 x 8 pattern.
    public static func colorFromPattern(_ pattern: Bitmap, topLeft: Point = .zero) -> LCDColor {
        var color: LCDColor = 0
        graphics.setColorToPattern.unsafelyUnwrapped(&color, pattern.pointer, CInt(topLeft.x), CInt(topLeft.y))
        return color
    }

    /// Sets the pixel at `point` in the current drawing context (by default the screen) to the given color.
    /// Be aware that setting a pixel at a time is not very efficient: In our testing, more than around 20,000
    /// calls in a tight loop will drop the frame rate below 30 fps.
    public static func setPixel(at point: Point, to color: Color) {
        color.withLCDColor {
            graphics.setPixel(CInt(point.x), CInt(point.y), $0)
        }
    }

    // MARK: Private

    private static var graphics: playdate_graphics { Playdate.playdateAPI.graphics.pointee }
}
