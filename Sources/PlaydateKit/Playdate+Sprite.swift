public import CPlaydate

public extension Playdate {
    enum Sprite {
        // MARK: Public

        public typealias Rect = PDRect
        public typealias CollisionResponseType = SpriteCollisionResponseType
        public typealias CollisionInfo = SpriteCollisionInfo
        public typealias QueryInfo = SpriteQueryInfo

        /// Allocates and returns a new LCDSprite.
        public static func newSprite() -> OpaquePointer {
            sprite.newSprite().unsafelyUnwrapped
        }

        /// Allocates and returns a copy of the given sprite.
        public static func copy(_ sprite: OpaquePointer) -> OpaquePointer {
            Sprite.sprite.copy(sprite).unsafelyUnwrapped
        }

        /// Frees the given sprite.
        public static func freeSprite(_ sprite: OpaquePointer) {
            Sprite.sprite.freeSprite(sprite)
        }

        // MARK: - Properties

        /// Sets the bounds of the given sprite with `bounds`.
        public static func setBounds(_ sprite: OpaquePointer, bounds: Rect) {
            Sprite.sprite.setBounds(sprite, bounds)
        }

        /// Returns the bounds of the given sprite as an `PDRect`.
        public static func getBounds(_ sprite: OpaquePointer) -> Rect {
            Sprite.sprite.getBounds(sprite)
        }

        /// Moves the given sprite to `x`, `y` and resets its bounds based on the bitmap dimensions and center.
        public static func moveTo(_ sprite: OpaquePointer, x: Float, y: Float) {
            Sprite.sprite.moveTo(sprite, x, y)
        }

        /// Moves the given sprite to by offsetting its current position by `dx`, `dy`.
        public static func moveBy(_ sprite: OpaquePointer, dx: Float, dy: Float) {
            Sprite.sprite.moveBy(sprite, dx, dy)
        }

        /// Gets the current position of sprite.
        public static func getPosition(_ sprite: OpaquePointer) -> (x: Float, y: Float) {
            var x: Float = 0, y: Float = 0
            Sprite.sprite.getPosition(sprite, &x, &y)
            return (x, y)
        }

        /// Sets the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width. Default is 0.5, 0.5 (the center of the sprite).
        /// This means that when you call `moveTo(sprite, x, y)`, the center of your sprite will be positioned at x, y.
        /// If you want x and y to represent the upper left corner of your sprite, specify the center as 0, 0.
        public static func setCenter(_ sprite: OpaquePointer, x: Float, y: Float) {
            Sprite.sprite.setCenter(sprite, x, y)
        }

        /// Returns the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width.
        public static func getCenter(_ sprite: OpaquePointer) -> (x: Float, y: Float) {
            var x: Float = 0, y: Float = 0
            Sprite.sprite.getCenter(sprite, &x, &y)
            return (x, y)
        }

        /// Sets the given sprite's image to the given bitmap.
        public static func setImage(_ sprite: OpaquePointer, image: OpaquePointer, flip: Graphics.Bitmap.Flip) {
            Sprite.sprite.setImage(sprite, image, flip)
        }

        /// Returns the `LCDBitmap` currently assigned to the given sprite.
        public static func getImage(_ sprite: OpaquePointer) -> OpaquePointer? {
            Sprite.sprite.getImage(sprite)
        }

        /// Sets the size. The size is used to set the sprite’s bounds when calling `moveTo()`.
        public static func setSize(_ sprite: OpaquePointer, width: Float, height: Float) {
            Sprite.sprite.setSize(sprite, width, height)
        }

        /// Sets the Z order of the given sprite. Higher Z sprites are drawn on top of those with lower Z order.
        public static func setZIndex(_ sprite: OpaquePointer, zIndex: Int16) {
            Sprite.sprite.setZIndex(sprite, zIndex)
        }

        /// Returns the Z index of the given sprite.
        public static func getZIndex(_ sprite: OpaquePointer) -> Int16 {
            Sprite.sprite.getZIndex(sprite)
        }

        /// Sets the tag of the given sprite. This can be useful for identifying sprites or types of sprites when using the collision API.
        public static func setTag(_ sprite: OpaquePointer, tag: UInt8) {
            Sprite.sprite.setTag(sprite, tag)
        }

        /// Returns the tag of the given sprite.
        public static func getTag(_ sprite: OpaquePointer) -> UInt8 {
            Sprite.sprite.getTag(sprite)
        }

        /// Sets the mode for drawing the sprite’s bitmap.
        public static func setDrawMode(_ sprite: OpaquePointer, drawMode: Graphics.Bitmap.DrawMode) {
            Sprite.sprite.setDrawMode(sprite, drawMode)
        }

        /// Flips the bitmap.
        public static func setImageFlip(_ sprite: OpaquePointer, flip: Graphics.Bitmap.Flip) {
            Sprite.sprite.setImageFlip(sprite, flip)
        }

        /// Returns the flip setting of the sprite’s bitmap.
        public static func getImageFlip(_ sprite: OpaquePointer) -> Graphics.Bitmap.Flip {
            Sprite.sprite.getImageFlip(sprite)
        }

        /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn.
        public static func setStencil(_ sprite: OpaquePointer, stencil: OpaquePointer) {
            Sprite.sprite.setStencil(sprite, stencil)
        }

        /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn. If `tile` is set, the stencil will be tiled.
        /// Tiled stencils must have width evenly divisible by 32.
        public static func setStencilImage(_ sprite: OpaquePointer, stencil: OpaquePointer, tile: Int32) {
            Sprite.sprite.setStencilImage(sprite, stencil, tile)
        }

        /// Sets the sprite’s stencil to the given pattern.
        public static func setStencilPattern(_ sprite: OpaquePointer, pattern: UnsafeMutablePointer<UInt8>) {
            Sprite.sprite.setStencilPattern(sprite, pattern)
        }

        /// Clears the sprite’s stencil.
        public static func clearStencil(_ sprite: OpaquePointer) {
            Sprite.sprite.clearStencil(sprite)
        }

        /// Sets the clipping rectangle for sprite drawing.
        public static func setClipRect(_ sprite: OpaquePointer, clipRect: Graphics.Rect) {
            Sprite.sprite.setClipRect(sprite, clipRect)
        }

        /// Clears the sprite’s clipping rectangle.
        public static func clearClipRect(_ sprite: OpaquePointer) {
            Sprite.sprite.clearClipRect(sprite)
        }

        /// Sets the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
        public static func setClipRectsInRange(clipRect: Graphics.Rect, startZ: Int32, endZ: Int32) {
            sprite.setClipRectsInRange(clipRect, startZ, endZ)
        }

        /// Clears the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
        public static func clearClipRectsInRange(startZ: Int32, endZ: Int32) {
            sprite.clearClipRectsInRange(startZ, endZ)
        }

        /// Set the updatesEnabled flag of the given sprite (determines whether the sprite has its update function called).
        public static func setUpdatesEnabled(_ sprite: OpaquePointer, enabled: Bool) {
            Sprite.sprite.setUpdatesEnabled(sprite, enabled ? 1 : 0)
        }

        /// Get the updatesEnabled flag of the given sprite.
        public static func updatesEnabled(_ sprite: OpaquePointer) -> Bool {
            Sprite.sprite.updatesEnabled(sprite) != 0
        }

        /// Set the `visible` flag of the given sprite (determines whether the sprite has its draw function called).
        public static func setVisible(_ sprite: OpaquePointer, visible: Bool) {
            Sprite.sprite.setVisible(sprite, visible ? 1 : 0)
        }

        /// Get the `visible` flag of the given sprite.
        public static func isVisible(_ sprite: OpaquePointer) -> Bool {
            Sprite.sprite.isVisible(sprite) != 0
        }

        /// Marking a sprite opaque tells the sprite system that it doesn’t need to draw anything underneath the sprite,
        /// since it will be overdrawn anyway. If you set an image without a mask/alpha channel on the sprite, it automatically
        /// sets the `opaque` flag.
        public static func setOpaque(_ sprite: OpaquePointer, opaque: Bool) {
            Sprite.sprite.setOpaque(sprite, opaque ? 1 : 0)
        }

        /// When `alwaysRedraw` is set to true, this causes all sprites to draw each frame, whether or not they have been marked dirty.
        /// This may speed up the performance of your game if the system’s dirty rect tracking is taking up too much time - for example
        /// if there are many sprites moving around on screen at once.
        public static func setAlwaysRedraw(_ alwaysRedraw: Bool) {
            sprite.setAlwaysRedraw(alwaysRedraw ? 1 : 0)
        }

        /// Forces the given sprite to redraw.
        public static func markDirty(_ sprite: OpaquePointer) {
            Sprite.sprite.markDirty(sprite)
        }

        /// Marks the given dirtyRect (in screen coordinates) as needing a redraw. Graphics drawing functions now call this
        /// automatically, adding their drawn areas to the sprite’s dirty list, so there’s usually no need to call this manually.
        public static func addDirtyRect(_ dirtyRect: Graphics.Rect) {
            sprite.addDirtyRect(dirtyRect)
        }

        /// When `ignoresDrawOffset` is set to true, the sprite will draw in screen coordinates, ignoring the currently-set drawOffset.
        ///
        /// This only affects drawing, and should not be used on sprites being used for collisions, which will still happen in world-space.
        public static func setIgnoresDrawOffset(_ sprite: OpaquePointer, ignoresDrawOffset: Bool) {
            Sprite.sprite.setIgnoresDrawOffset(sprite, ignoresDrawOffset ? 1 : 0)
        }

        /// Sets the update function for the given sprite.
        public static func setUpdateFunction(_ sprite: OpaquePointer, updateFunction: (@convention(c) (_ sprite: OpaquePointer?) -> Void)?) {
            Sprite.sprite.setUpdateFunction(sprite, updateFunction)
        }

        /// Sets the draw function for the given sprite. Note that the callback is only called when the
        /// sprite is on screen and has a size specified via `setSize()` or `setBounds()`.
        public static func setDrawFunction(_ sprite: OpaquePointer, drawFunction: (@convention(c) (_ sprite: OpaquePointer?, _ bounds: Rect, _ drawRect: Rect) -> Void)?) {
            Sprite.sprite.setDrawFunction(sprite, drawFunction)
        }

        /// Sets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.
        public static func setUserdata(_ sprite: OpaquePointer, userdata: UnsafeMutableRawPointer) {
            Sprite.sprite.setUserdata(sprite, userdata)
        }

        /// Gets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.
        public static func getUserdata(_ sprite: OpaquePointer) -> UnsafeMutableRawPointer? {
            Sprite.sprite.getUserdata(sprite)
        }

        // MARK: - Display List

        /// Adds the given sprite to the display list, so that it is drawn in the current scene.
        public static func addSprite(_ sprite: OpaquePointer) {
            Sprite.sprite.addSprite(sprite)
        }

        /// Removes the given sprite from the display list.
        public static func removeSprite(_ sprite: OpaquePointer) {
            Sprite.sprite.removeSprite(sprite)
        }

        /// Removes the given `count` sized array of sprites from the display list.
        public static func removeSprites(_ sprites: UnsafeMutablePointer<OpaquePointer?>, count: Int32) {
            Sprite.sprite.removeSprites(sprites, count)
        }

        /// Removes all sprites from the display list.
        public static func removeAllSprites() {
            sprite.removeAllSprites()
        }

        /// Returns the total number of sprites in the display list.
        public static func getSpriteCount() -> Int32 {
            sprite.getSpriteCount()
        }

        /// Draws every sprite in the display list.
        public static func drawSprites() {
            sprite.drawSprites()
        }

        /// Updates and draws every sprite in the display list.
        public static func updateAndDrawSprites() {
            sprite.updateAndDrawSprites()
        }

        // MARK: - Collisions

        /// Frees and reallocates internal collision data, resetting everything to its default state.
        public static func resetCollisionWorld() {
            sprite.resetCollisionWorld()
        }

        /// Set the `collisionsEnabled` flag of the given sprite (along with the collideRect, this
        /// determines whether the sprite participates in collisions). Set to true by default.
        public static func setCollisionsEnabled(_ sprite: OpaquePointer, enabled: Bool) {
            Sprite.sprite.setCollisionsEnabled(sprite, enabled ? 1 : 0)
        }

        /// Get the `collisionsEnabled` flag of the given sprite.
        public static func collisionsEnabled(_ sprite: OpaquePointer) -> Bool {
            Sprite.sprite.collisionsEnabled(sprite) != 0
        }

        /// Marks the area of the given sprite, relative to its bounds, to be checked for collisions with other sprites' collide rects.
        public static func setCollideRect(_ sprite: OpaquePointer, collideRect: Rect) {
            Sprite.sprite.setCollideRect(sprite, collideRect)
        }

        /// Returns the given sprite’s collide rect.
        public static func getCollideRect(_ sprite: OpaquePointer) -> Rect? {
            Sprite.sprite.getCollideRect(sprite)
        }

        /// Clears the given sprite’s collide rect.
        public static func clearCollideRect(_ sprite: OpaquePointer) {
            Sprite.sprite.clearCollideRect(sprite)
        }

        /// Set a callback that returns a `SpriteCollisionResponseType` for a collision between `sprite` and other.
        public static func setCollisionResponseFunction(_ sprite: OpaquePointer, function: (@convention(c) (_ sprite: OpaquePointer?, _ other: OpaquePointer?) -> CollisionResponseType)?) {
            Sprite.sprite.setCollisionResponseFunction(sprite, function)
        }

        /// Returns the same values as `moveWithCollisions()` but does not actually move the sprite.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func checkCollisions(_ sprite: OpaquePointer, goalX: Float, goalY: Float) -> (collisionInfo: UnsafeMutableBufferPointer<CollisionInfo>, actualX: Float, actualY: Float) {
            var actualX: Float = 0, actualY: Float = 0
            var length: Int32 = 0
            let collisionInfo = Sprite.sprite.checkCollisions(sprite, goalX, goalY, &actualX, &actualY, &length)
            return (UnsafeMutableBufferPointer(start: collisionInfo, count: Int(length)), actualX, actualY)
        }

        /// Moves the given sprite towards `goalX`, `goalY` taking collisions into account and returns an array of `SpriteCollisionInfo`.
        /// `actualX`, `actualY` are set to the sprite’s position after collisions. If no collisions occurred, this will be the same as
        /// `goalX`, `goalY`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func moveWithCollisions(_ sprite: OpaquePointer, goalX: Float, goalY: Float) -> (collisionInfo: UnsafeMutableBufferPointer<CollisionInfo>, actualX: Float, actualY: Float) {
            var actualX: Float = 0, actualY: Float = 0
            var length: Int32 = 0
            let collisionInfo = Sprite.sprite.moveWithCollisions(sprite, goalX, goalY, &actualX, &actualY, &length)
            return (UnsafeMutableBufferPointer(start: collisionInfo, count: Int(length)), actualX, actualY)
        }

        /// Returns an array of all sprites with collision rects containing the point at `x`, `y`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesAtPoint(x: Float, y: Float) -> UnsafeMutableBufferPointer<OpaquePointer?> {
            var length: Int32 = 0
            let sprites = sprite.querySpritesAtPoint(x, y, &length)
            return UnsafeMutableBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of all sprites with collision rects that intersect the `width` by `height` rect at `x`, `y`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesInRect(x: Float, y: Float, width: Float, height: Float) -> UnsafeMutableBufferPointer<OpaquePointer?> {
            var length: Int32 = 0
            let sprites = sprite.querySpritesInRect(x, y, width, height, &length)
            return UnsafeMutableBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of all sprites with collision rects that intersect the line connecting `x1`, `y1` and `x2`, `y2`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesAlongLine(x1: Float, y1: Float, x2: Float, y2: Float) -> UnsafeMutableBufferPointer<OpaquePointer?> {
            var length: Int32 = 0
            let sprites = sprite.querySpritesAlongLine(x1, y1, x2, y2, &length)
            return UnsafeMutableBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of `SpriteQueryInfo` for all sprites with collision rects that intersect the line connecting `x1`, `y1` and `x2`, `y2`.
        /// If you don’t need this information, use `querySpritesAlongLine()` as it will be faster.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpriteInfoAlongLine(x1: Float, y1: Float, x2: Float, y2: Float) -> UnsafeMutableBufferPointer<QueryInfo> {
            var length: Int32 = 0
            let spriteInfo = sprite.querySpriteInfoAlongLine(x1, y1, x2, y2, &length)
            return UnsafeMutableBufferPointer(start: spriteInfo, count: Int(length))
        }

        /// Returns an array of sprites that have collide rects that are currently overlapping the given sprite’s collide rect.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func overlappingSprites(_ sprite: OpaquePointer) -> UnsafeMutableBufferPointer<OpaquePointer?> {
            var length: Int32 = 0
            let sprites = Sprite.sprite.overlappingSprites(sprite, &length)
            return UnsafeMutableBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of all sprites that have collide rects that are currently overlapping. Each consecutive pair of sprites is overlapping
        /// (eg. 0 & 1 overlap, 2 & 3 overlap, etc).
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func allOverlappingSprites() -> UnsafeMutableBufferPointer<OpaquePointer?> {
            var length: Int32 = 0
            let sprites = sprite.allOverlappingSprites(&length)
            return UnsafeMutableBufferPointer(start: sprites, count: Int(length))
        }

        // MARK: Private

        private static var sprite: playdate_sprite { playdateAPI.sprite.pointee }
    }
}
