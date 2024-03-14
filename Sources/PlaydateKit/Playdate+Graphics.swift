@preconcurrency public import CPlaydate

public extension Playdate {
    enum Graphics {
        // MARK: Public

        public enum Video {
            // MARK: Public

            /// Opens the pdv file at path and returns a new video player object for rendering its frames.
            public static func loadVideo(path: StaticString) -> OpaquePointer {
                video.loadVideo(path.utf8Start).unsafelyUnwrapped
            }

            public static func freePlayer(_ player: OpaquePointer) {
                video.freePlayer(player)
            }

            public static func setContext(player: OpaquePointer, context: OpaquePointer) throws(Error) {
                guard video.setContext(player, context) != 0 else {
                    throw getError(player)
                }
            }

            public static func getContext(player: OpaquePointer) -> OpaquePointer {
                video.getContext(player).unsafelyUnwrapped
            }

            public static func useScreenContext(_ player: OpaquePointer) {
                video.useScreenContext(player)
            }

            public static func renderFrame(player: OpaquePointer, frameNumber: Int32) throws(Error) {
                guard video.renderFrame(player, frameNumber) != 0 else {
                    throw getError(player)
                }
            }

            /// Returns human-readable text describing the most recent error
            /// (usually indicated by a -1 return from a filesystem function).
            public static func getError(_ player: OpaquePointer) -> Error {
                Error(humanReadableText: video.getError(player))
            }

            public static func getInfo(player: OpaquePointer) -> (
                width: Int32, height: Int32,
                frameRate: Float,
                frameCount: Int32, currentFrame: Int32
            ) {
                var width: Int32 = 0, height: Int32 = 0
                var frameRate: Float = 0
                var frameCount: Int32 = 0, currentFrame: Int32 = 0
                video.getInfo(player, &width, &height, &frameRate, &frameCount, &currentFrame)
                return (width, height, frameRate, frameCount, currentFrame)
            }

            // MARK: Private

            private static var video: playdate_video { graphics.video.pointee }
        }

        /// The tracking to use when drawing text.
        public static var textTracking: Int32 {
            get { graphics.getTextTracking() }
            set { graphics.setTextTracking(newValue) }
        }

        /// Push a new drawing context for drawing into the given bitmap.
        /// If context is nil, the drawing functions will use the display framebuffer.
        public static func pushContext(_ context: OpaquePointer?) {
            graphics.pushContext(context)
        }

        /// Pops a context off the stack (if any are left), restoring the drawing settings from before the context was pushed.
        public static func popContext() {
            graphics.popContext()
        }

        /// Sets the stencil used for drawing. For a tiled stencil, use setStencilImage() instead.
        /// To clear the stencil, set it to nil.
        public static func setStencil(_ stencil: OpaquePointer?) {
            graphics.setStencil(stencil)
        }

        /// Sets the stencil used for drawing. If `tile` is true the stencil image will be tiled.
        /// Tiled stencils must have width equal to a multiple of 32 pixels.
        /// To clear the stencil, call `setStencil(nil)`.
        public static func setStencilImage(_ stencil: OpaquePointer, tile: Bool) {
            graphics.setStencilImage(stencil, tile ? 1 : 0)
        }

        /// Sets the mode used for drawing bitmaps. Note that text drawing uses bitmaps, so this affects how fonts are displayed as well.
        public static func setDrawMode(_ mode: LCDBitmapDrawMode) {
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
        public static func setLineCapStyle(_ style: LCDLineCapStyle) {
            graphics.setLineCapStyle(style)
        }

        /// Sets the font to use in subsequent drawText calls.
        public static func setFont(_ font: OpaquePointer) {
            graphics.setFont(font)
        }

        /// Sets the leading adjustment (added to the leading specified in the font) to use when drawing text.
        public static func setTextLeading(_ leading: Int32) {
            graphics.setTextLeading(leading)
        }

        /// Clears `bitmap`, filling with the given `bgcolor`.
        public static func clearBitmap(_ bitmap: OpaquePointer, bgColor: LCDColor) {
            graphics.clearBitmap(bitmap, bgColor)
        }

        /// Returns a new LCDBitmap that is an exact copy of `bitmap`.
        public static func copyBitmap(_ bitmap: OpaquePointer) -> OpaquePointer {
            graphics.copyBitmap(bitmap).unsafelyUnwrapped
        }

        /// Returns true if any of the opaque pixels in `bitmap1` when positioned at `x1`, `y1` with `flip1` overlap any
        /// of the opaque pixels in `bitmap2` at `x2`, `y2` with `flip2` within the non-empty rect, or false
        /// if no pixels overlap or if one or both fall completely outside of rect.
        public static func checkMaskCollision(
            bitmap1: OpaquePointer,
            x1: Int32,
            y1: Int32,
            flip1: LCDBitmapFlip,
            bitmap2: OpaquePointer,
            x2: Int32,
            y2: Int32,
            flip2: LCDBitmapFlip,
            rect: LCDRect
        ) -> Bool {
            graphics.checkMaskCollision(bitmap1, x1, y1, flip1, bitmap2, x2, y2, flip2, rect) != 0
        }

        /// Draws the `bitmap` with its upper-left corner at location `x`, `y`, using the given `flip` orientation.
        public static func drawBitmap(_ bitmap: OpaquePointer, x: Int32, y: Int32, flip: LCDBitmapFlip) {
            graphics.drawBitmap(bitmap, x, y, flip)
        }

        /// Draws the `bitmap` scaled to `xScale` and `yScale` with its upper-left corner at location `x`, `y`.
        /// Note that `flip` is not available when drawing scaled bitmaps but negative scale values will achieve the same effect.
        public static func drawScaledBitmap(
            _ bitmap: OpaquePointer,
            x: Int32,
            y: Int32,
            xScale: Float,
            yScale: Float
        ) {
            graphics.drawScaledBitmap(bitmap, x, y, xScale, yScale)
        }

        /// Draws the `bitmap` scaled to `xScale` and `yScale` then rotated by `degrees` with its center as given by proportions
        /// `centerX` and `centerY` at `x`, `y`; that is: if `centerX` and `centerY` are both 0.5 the center of the image is at (x,y),
        /// if `centerX` and `centerY` are both 0 the top left corner of the image (before rotation) is at (x,y), etc.
        public static func drawRotatedBitmap(
            _ bitmap: OpaquePointer,
            x: Int32,
            y: Int32,
            degrees: Float,
            centerX: Float,
            centerY: Float,
            xScale: Float,
            yScale: Float
        ) {
            graphics.drawRotatedBitmap(bitmap, x, y, degrees, centerX, centerY, xScale, yScale)
        }

        /// Frees the given `bitmap`.
        public static func freeBitmap(_ bitmap: OpaquePointer) {
            graphics.freeBitmap(bitmap)
        }

        /// Gets various info about `bitmap` including its `width` and `height` and raw pixel `data`.
        /// The data is 1 bit per pixel packed format, in MSB order; in other words, the high bit of the first byte
        /// in data is the top left pixel of the image. If the bitmap has a mask, a pointer to its data is returned in `mask`,
        /// else nil is returned.
        public static func getBitmapData(
            _ bitmap: OpaquePointer,
            mask: inout UnsafeMutablePointer<UInt8>?,
            data: inout UnsafeMutablePointer<UInt8>?
        ) -> (
            width: Int32, height: Int32, rowBytes: Int32
        ) {
            var width: Int32 = 0, height: Int32 = 0, rowBytes: Int32 = 0
            graphics.getBitmapData(bitmap, &width, &height, &rowBytes, &mask, &data)
            return (width, height, rowBytes)
        }

        /// Allocates and returns a new `LCDBitmap` from the file at path. If there is no file at `path`, the function returns nil.
        public static func loadBitmap(path: StaticString) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let bitmap = graphics.loadBitmap(path.utf8Start, &error)
            if let error { throw Error(humanReadableText: error) }
            return bitmap
        }

        /// Allocates and returns a new `LCDBitmap` from the file at path. If there is no file at `path`, the function returns nil.
        public static func loadBitmap(path: UnsafeMutablePointer<CChar>) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let bitmap = graphics.loadBitmap(path, &error)
            if let error { throw Error(humanReadableText: error) }
            return bitmap
        }

        /// Loads the image at `path` into the previously allocated `bitmap`.
        public static func loadIntoBitmap(path: StaticString, bitmap: OpaquePointer) throws(Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmap(path.utf8Start, bitmap, &error)
            if let error { throw Error(humanReadableText: error) }
        }

        /// Loads the image at `path` into the previously allocated `bitmap`.
        public static func loadIntoBitmap(path: UnsafeMutablePointer<CChar>, bitmap: OpaquePointer) throws(Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmap(path, bitmap, &error)
            if let error { throw Error(humanReadableText: error) }
        }

        /// Allocates and returns a new `width` by `height` `LCDBitmap` filled with `bgcolor`.
        public static func newBitmap(width: Int32, height: Int32, bgColor: LCDColor) -> OpaquePointer {
            graphics.newBitmap(width, height, bgColor).unsafelyUnwrapped
        }

        /// Draws the `bitmap` with its upper-left corner at location `x`, `y` tiled inside a `width` by `height` rectangle.
        public static func tileBitmap(_ bitmap: OpaquePointer, x: Int32, y: Int32, width: Int32, height: Int32, flip: LCDBitmapFlip) {
            graphics.tileBitmap(bitmap, x, y, width, height, flip)
        }

        /// Returns a new, rotated and scaled `LCDBitmap` based on the given `bitmap`.
        public static func rotatedBitmap(_ bitmap: OpaquePointer, rotation: Float, xScale: Float, yScale: Float) -> (bitmap: OpaquePointer, allocatedSize: Int32) {
            var allocatedSize: Int32 = 0
            let bitmap = graphics.rotatedBitmap(bitmap, rotation, xScale, yScale, &allocatedSize).unsafelyUnwrapped
            return (bitmap, allocatedSize)
        }

        /// Sets a `mask` image for the given `bitmap`. The set mask must be the same size as the target bitmap.
        public static func setBitmapMask(_ bitmap: OpaquePointer, mask: OpaquePointer) -> Int32 {
            // TODO: - Figure out what this returns
            graphics.setBitmapMask(bitmap, mask)
        }

        /// Gets a `mask` image for the given `bitmap`, or returns nil if the bitmap doesn’t have a mask layer.
        /// The returned image points to bitmap's data, so drawing into the mask image affects the source bitmap directly.
        /// The caller takes ownership of the returned `LCDBitmap` and is responsible for freeing it when it’s no longer in use.
        public static func getBitmapMask(_ bitmap: OpaquePointer) -> OpaquePointer? {
            graphics.getBitmapMask(bitmap)
        }

        /// Returns the `index` bitmap in `table`, If `index` is out of bounds, the function returns nil.
        public static func getTableBitmap(_ table: OpaquePointer, index: Int32) -> OpaquePointer? {
            graphics.getTableBitmap(table, index)
        }

        /// Allocates and returns a new `LCDBitmap` from the file at `path`. If there is no file at `path`, the function returns nil.
        public static func loadBitmapTable(path: StaticString) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let bitmapTable = graphics.loadBitmapTable(path.utf8Start, nil)
            if let error { throw Error(humanReadableText: error) }
            return bitmapTable
        }

        /// Allocates and returns a new `LCDBitmap` from the file at `path`. If there is no file at `path`, the function returns nil.
        public static func loadBitmapTable(path: UnsafeMutablePointer<CChar>) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let bitmapTable = graphics.loadBitmapTable(path, &error)
            if let error { throw Error(humanReadableText: error) }
            return bitmapTable
        }

        /// Loads the image table at `path` into the previously allocated `table`.
        public static func loadIntoBitmapTable(path: StaticString, table: OpaquePointer) throws(Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmapTable(path.utf8Start, table, &error)
            if let error { throw Error(humanReadableText: error) }
        }

        /// Loads the image table at `path` into the previously allocated `table`.
        public static func loadIntoBitmapTable(path: UnsafeMutablePointer<CChar>, table: OpaquePointer) throws(Error) {
            var error: UnsafePointer<CChar>?
            graphics.loadIntoBitmapTable(path, table, &error)
            if let error { throw Error(humanReadableText: error) }
        }

        /// Allocates and returns a new `LCDBitmapTable` that can hold `count` `width` by `height` `LCDBitmaps`.
        public static func newBitmapTable(count: Int32, width: Int32, height: Int32) -> OpaquePointer {
            graphics.newBitmapTable(count, width, height).unsafelyUnwrapped
        }

        /// Frees the given bitmap table. Note that this will invalidate any bitmaps returned by `getTableBitmap()`.
        public static func freeBitmapTable(_ table: OpaquePointer) {
            graphics.freeBitmapTable(table)
        }

        /// Draws the given `text` using the provided options. If no font has been set with `setFont`, the default
        /// system font Asheville Sans 14 Light is used.
        public static func drawText(
            _ text: UnsafeRawPointer?,
            length: Int,
            encoding: PDStringEncoding,
            x: Int32,
            y: Int32
        ) -> Int32 {
            // TODO: - Figure out what this returns
            graphics.drawText(text, length, encoding, x, y)
        }

        /// Returns the height of the given font.
        public static func getFontHeight(_ font: OpaquePointer) -> UInt8 {
            graphics.getFontHeight(font)
        }

        /// Returns an `LCDFontPage` object for the given character code. Each `LCDFontPage` contains information
        /// for 256 characters; specifically, if `(c1 & ~0xff) == (c2 & ~0xff)`, then `c1` and `c2` belong to the
        /// same page and the same `LCDFontPage` can be used to fetch the character data for both instead of searching
        /// for the page twice.
        public static func getFontPage(_ font: OpaquePointer, c: UInt32) -> OpaquePointer? {
            graphics.getFontPage(font, c)
        }

        /// Returns an `LCDFontGlyph` object for character `c` in `LCDFontPage` page, and returns the glyph’s
        /// `bitmap` and `advance` value.
        public static func getPageGlyph(
            _ page: OpaquePointer,
            c: UInt32,
            bitmap: inout OpaquePointer?
        ) -> (pageGlyph: OpaquePointer?, advance: Int32) {
            var advance: Int32 = 0
            let pageGlyph = graphics.getPageGlyph(page, c, &bitmap, &advance)
            return (pageGlyph, advance)
        }

        /// Returns the kerning adjustment between characters `c1` and `c2` as specified by the font.
        public static func getGlyphKerning(_ glyph: OpaquePointer, c1: UInt32, c2: UInt32) -> Int32 {
            graphics.getGlyphKerning(glyph, c1, c2)
        }

        /// Returns the width of the given `text` in the given `font`.
        public static func getTextWidth(
            _ font: OpaquePointer,
            text: UnsafeRawPointer,
            length: Int,
            encoding: PDStringEncoding,
            tracking: Int32
        ) -> Int32 {
            graphics.getTextWidth(font, text, length, encoding, tracking)
        }

        /// Returns the `LCDFont` object for the font file at `path`. The returned font can be freed with
        /// `Playdate.System.realloc(font, 0)` when it is no longer in use.
        public static func loadFont(path: StaticString) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let font = graphics.loadFont(path.utf8Start, &error)
            if let error { throw Error(humanReadableText: error) }
            return font
        }

        /// Returns the `LCDFont` object for the font file at `path`. The returned font can be freed with
        /// `Playdate.System.realloc(font, 0)` when it is no longer in use.
        public static func loadFont(path: UnsafeMutablePointer<CChar>) throws(Error) -> OpaquePointer? {
            var error: UnsafePointer<CChar>?
            let font = graphics.loadFont(path, &error)
            if let error { throw Error(humanReadableText: error) }
            return font
        }

        /// Returns an `LCDFont` object wrapping the `LCDFontData` `data` comprising the contents (minus 16-byte header)
        /// of an uncompressed pft file. `wide` corresponds to the flag in the header indicating whether the font contains
        /// glyphs at codepoints above U+1FFFF.
        public static func makeFontFromData(_ data: OpaquePointer, wide: Bool) -> OpaquePointer? {
            graphics.makeFontFromData(data, wide ? 1 : 0)
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
            color: LCDColor
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
            color: LCDColor
        ) {
            graphics.fillEllipse(x, y, width, height, startAngle, endAngle, color)
        }

        /// Draws a line from `x1`, `y1` to `x2`, `y2` with a stroke width of `lineWidth`.
        public static func drawLine(x1: Int32, y1: Int32, x2: Int32, y2: Int32, lineWidth: Int32, color: LCDColor) {
            graphics.drawLine(x1, y1, x2, y2, lineWidth, color)
        }

        /// Draws a `width` by `height` rect at `x`, `y`.
        public static func drawRect(x: Int32, y: Int32, width: Int32, height: Int32, color: LCDColor) {
            graphics.drawRect(x, y, width, height, color)
        }

        /// Draws a filled `width` by `height` rect at `x`, `y`.
        public static func fillRect(x: Int32, y: Int32, width: Int32, height: Int32, color: LCDColor) {
            graphics.fillRect(x, y, width, height, color)
        }

        /// Draws a filled triangle with points at `x1`, `y1`, `x2`, `y2`, and `x3`, `y3`.
        public static func fillTriangle(x1: Int32, y1: Int32, x2: Int32, y2: Int32, x3: Int32, y3: Int32, color: LCDColor) {
            graphics.fillTriangle(x1, y1, x2, y2, x3, y3, color)
        }

        /// Fills the polygon with vertices at the given coordinates (an array of 2*nPoints ints containing alternating x and y values)
        /// using the given `color` and fill, or winding, rule. See https://en.wikipedia.org/wiki/Nonzero-rule
        /// for an explanation of the winding rule. An edge between the last vertex and the first is assumed.
        public static func fillPolygon(numberOfPoints: Int32, points: UnsafeMutablePointer<UInt32>, color: LCDColor, fillRule: LCDPolygonFillRule) {
            graphics.fillPolygon(numberOfPoints, points, color, fillRule)
        }

        /// Clears the entire display, filling it with `color`.
        public static func clear(color: LCDColor) {
            graphics.clear(color)
        }

        /// Sets the background color shown when the display is offset or for clearing dirty areas in the sprite system.
        public static func setBackgroundColor(color: LCDSolidColor) {
            graphics.setBackgroundColor(color)
        }

        /// Manually flushes the current frame buffer out to the display. This function is automatically called
        /// after each pass through the run loop, so there shouldn’t be any need to call it yourself.
        public static func display() {
            graphics.display()
        }

        /// Only valid in the Simulator; function returns nil on device. Returns the debug framebuffer as a bitmap.
        /// White pixels drawn in the image are overlaid on the display in 50% transparent red.
        public static func getDebugBitmap() -> OpaquePointer? {
            graphics.getDebugBitmap()
        }

        /// Returns the raw bits in the display buffer, the last completed frame.
        public static func getDisplayFrame() -> UnsafeMutablePointer<UInt8>? {
            graphics.getDisplayFrame()
        }

        /// Returns a bitmap containing the contents of the display buffer. The system owns this bitmap—​do not free it!
        public static func getDisplayBufferBitmap() -> OpaquePointer? {
            graphics.getDisplayBufferBitmap()
        }

        /// Returns the current display frame buffer. Rows are 32-bit aligned, so the row stride is 52 bytes,
        /// with the extra 2 bytes per row ignored. Bytes are MSB-ordered; i.e., the pixel in column 0 is the
        /// 0x80 bit of the first byte of the row.
        public static func getFrame() -> UnsafeMutablePointer<UInt8>? {
            graphics.getFrame()
        }

        /// Returns a copy the contents of the working frame buffer as a bitmap. The caller is responsible for
        /// freeing the returned bitmap with `freeBitmap()`.
        public static func copyFrameBufferBitmap() -> OpaquePointer? {
            graphics.copyFrameBufferBitmap()
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
        public static func colorFromPattern(bitmap: OpaquePointer, x: Int32, y: Int32) -> LCDColor {
            var color: LCDColor = 0
            graphics.setColorToPattern(&color, bitmap, x, y)
            return color
        }

        // MARK: Private

        private static var graphics: playdate_graphics { playdateAPI.graphics.pointee }
    }
}
