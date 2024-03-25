public import CPlaydate

/// Functions related to sprites.
///
/// Sprites are graphic objects that can be used to represent moving entities in your games, like the player,
/// or the enemies that chase after your player. Sprites animate efficiently, and offer collision detection and
/// a host of other built-in functionality.
public enum Sprite {
    // MARK: Public

    public typealias CollisionResponseType = SpriteCollisionResponseType

    public class CollisionInfo {
        // MARK: Lifecycle

        init(collisions: UnsafeBufferPointer<SpriteCollisionInfo>, actual: Point<Float>) {
            self.collisions = collisions
            self.actual = actual
        }

        deinit { collisions.deallocate() }

        // MARK: Public

        public let collisions: UnsafeBufferPointer<SpriteCollisionInfo>
        public let actual: Point<Float>
    }

    public class QueryInfo {
        // MARK: Lifecycle

        init(info: UnsafeBufferPointer<SpriteQueryInfo>) {
            self.info = info
        }

        deinit {
            info.deallocate()
        }

        // MARK: Public

        public let info: UnsafeBufferPointer<SpriteQueryInfo>
    }

    public class Sprite {
        // MARK: Lifecycle

        /// Allocates and returns a new Sprite.
        public init() {
            pointer = sprite.newSprite.unsafelyUnwrapped().unsafelyUnwrapped
        }

        init(pointer: OpaquePointer) {
            self.pointer = pointer
        }

        deinit { sprite.freeSprite.unsafelyUnwrapped(pointer) }

        // MARK: Public

        /// The sprite's stencil bitmap, if set.
        public private(set) var stencil: Graphics.Bitmap?

        /// The bitmap currently assigned to the sprite.
        public var image: Graphics.Bitmap? {
            didSet {
                sprite.setImage.unsafelyUnwrapped(pointer, image?.pointer, imageFlip)
            }
        }

        /// Gets the current position of sprite.
        public var position: Point<Float> {
            var x: Float = 0, y: Float = 0
            sprite.getPosition.unsafelyUnwrapped(pointer, &x, &y)
            return Point(x: x, y: y)
        }

        /// Gets/sets the bounds of the sprite.
        public var bounds: Rect<Float> {
            get { Rect(sprite.getBounds.unsafelyUnwrapped(pointer)) }
            set { sprite.setBounds.unsafelyUnwrapped(pointer, newValue.pdRect) }
        }

        /// Gets/sets the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width.
        /// Default is 0.5, 0.5 (the center of the sprite).
        /// This means that when you call `moveTo(x, y)`, the center of your sprite will be positioned at x, y.
        /// If you want x and y to represent the upper left corner of your sprite, specify the center as 0, 0.
        public var center: Point<Float> {
            get {
                var x: Float = 0, y: Float = 0
                sprite.getCenter.unsafelyUnwrapped(pointer, &x, &y)
                return Point(x: x, y: y)
            } set {
                sprite.setCenter.unsafelyUnwrapped(pointer, newValue.x, newValue.y)
            }
        }

        /// Gets/sets the Z order of the given sprite. Higher Z sprites are drawn on top of those with lower Z order.
        public var zIndex: Int16 {
            get { sprite.getZIndex.unsafelyUnwrapped(pointer) }
            set { sprite.setZIndex.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Gets/sets the tag of the given sprite. This can be useful for identifying sprites or types of sprites when using the collision API.
        public var tag: UInt8 {
            get { sprite.getTag.unsafelyUnwrapped(pointer) }
            set { sprite.setTag.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Flips the bitmap.
        public var imageFlip: Graphics.Bitmap.Flip {
            get { sprite.getImageFlip.unsafelyUnwrapped(pointer) }
            set { sprite.setImageFlip.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Get/set the `updatesEnabled` flag of the sprite (determines whether the sprite has its update function called).
        public var updatesEnabled: Bool {
            get { sprite.updatesEnabled.unsafelyUnwrapped(pointer) != 0 }
            set { sprite.setUpdatesEnabled.unsafelyUnwrapped(pointer, newValue ? 1 : 0) }
        }

        /// Set the `visible` flag of the sprite (determines whether the sprite has its draw function called).
        public var isVisible: Bool {
            get { sprite.isVisible.unsafelyUnwrapped(pointer) != 0 }
            set { sprite.setVisible.unsafelyUnwrapped(pointer, newValue ? 1 : 0) }
        }

        /// Gets/sets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.
        public var userdata: UnsafeMutableRawPointer? {
            get { sprite.getUserdata.unsafelyUnwrapped(pointer) }
            set { sprite.setUserdata.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Get/set the `collisionsEnabled` flag of the sprite (along with the `collideRect`, this
        /// determines whether the sprite participates in collisions). Set to true by default.
        public var collisionsEnabled: Bool {
            get { sprite.collisionsEnabled.unsafelyUnwrapped(pointer) != 0 }
            set { sprite.setCollisionsEnabled.unsafelyUnwrapped(pointer, newValue ? 1 : 0) }
        }

        /// Marks the area of the given sprite, relative to its bounds, to be checked for collisions with other sprites' collide rects.
        public var collideRect: Rect<Float>? {
            get { Rect(sprite.getCollideRect.unsafelyUnwrapped(pointer)) }
            set {
                if let newValue {
                    sprite.setCollideRect.unsafelyUnwrapped(pointer, newValue.pdRect)
                } else {
                    sprite.clearCollideRect.unsafelyUnwrapped(pointer)
                }
            }
        }

        /// Returns an array of sprites that have collide rects that are currently overlapping the given sprite’s collide rect.
        /// > Warning: The caller is responsible for freeing the returned array.
        public var overlappingSprites: UnsafeBufferPointer<OpaquePointer?> {
            // TODO: - Return array of sprites? figure out memory management
            var length: CInt = 0
            let sprites = sprite.overlappingSprites.unsafelyUnwrapped(pointer, &length)
            return UnsafeBufferPointer(start: sprites, count: Int(length))
        }

        /// Allocates and returns a copy of the sprite.
        public func copy() -> Sprite {
            Sprite(pointer: sprite.copy.unsafelyUnwrapped(pointer).unsafelyUnwrapped)
        }

        /// Moves the sprite to `point` and resets its bounds based on the bitmap dimensions and center.
        public func moveTo(_ point: Point<Float>) {
            sprite.moveTo.unsafelyUnwrapped(pointer, point.x, point.y)
        }

        /// Moves the sprite to by offsetting its current position by `dx`, `dy`.
        public func moveBy(dx: Float, dy: Float) {
            sprite.moveBy.unsafelyUnwrapped(pointer, dx, dy)
        }

        /// Sets the size. The size is used to set the sprite’s bounds when calling `moveTo()`.
        public func setSize(width: Float, height: Float) {
            sprite.setSize.unsafelyUnwrapped(pointer, width, height)
        }

        /// Sets the mode for drawing the sprite’s bitmap.
        public func setDrawMode(_ drawMode: Graphics.Bitmap.DrawMode) {
            sprite.setDrawMode.unsafelyUnwrapped(pointer, drawMode)
        }

        /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn.
        /// Pass `nil` to clear the sprite’s stencil.
        public func setStencil(_ stencil: Graphics.Bitmap?) {
            self.stencil = stencil
            if let stencil {
                sprite.setStencil.unsafelyUnwrapped(pointer, stencil.pointer)
            } else {
                sprite.clearStencil.unsafelyUnwrapped(pointer)
            }
        }

        /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn. If `tile` is set, the stencil will be tiled.
        /// Tiled stencils must have width evenly divisible by 32.
        public func setStencilImage(_ stencil: Graphics.Bitmap, tile: CInt) {
            self.stencil = stencil
            sprite.setStencilImage.unsafelyUnwrapped(pointer, stencil.pointer, tile)
        }

        /// Sets the sprite’s stencil to the given pattern.
        public func setStencilPattern(_ pattern: UnsafeMutablePointer<UInt8>) {
            sprite.setStencilPattern.unsafelyUnwrapped(pointer, pattern)
            stencil = nil
        }

        /// Sets the clipping rectangle for sprite drawing.
        /// Pass `nil` to clear the sprite’s clipping rectangle.
        public func setClipRect(_ clipRect: Rect<CInt>?) {
            if let clipRect {
                sprite.setClipRect.unsafelyUnwrapped(pointer, clipRect.lcdRect)
            } else {
                sprite.clearClipRect.unsafelyUnwrapped(pointer)
            }
        }

        /// Marking a sprite opaque tells the sprite system that it doesn’t need to draw anything underneath the sprite,
        /// since it will be overdrawn anyway. If you set an image without a mask/alpha channel on the sprite, it automatically
        /// sets the `opaque` flag.
        public func setOpaque(_ opaque: Bool) {
            sprite.setOpaque.unsafelyUnwrapped(pointer, opaque ? 1 : 0)
        }

        /// Forces the sprite to redraw.
        public func markDirty() {
            sprite.markDirty.unsafelyUnwrapped(pointer)
        }

        /// When `ignoresDrawOffset` is set to true, the sprite will draw in screen coordinates, ignoring the currently-set drawOffset.
        ///
        /// This only affects drawing, and should not be used on sprites being used for collisions, which will still happen in world-space.
        public func setIgnoresDrawOffset(_ ignoresDrawOffset: Bool) {
            sprite.setIgnoresDrawOffset.unsafelyUnwrapped(pointer, ignoresDrawOffset ? 1 : 0)
        }

        /// Sets the update function for the sprite.
        public func setUpdateFunction(
            _ updateFunction: (@convention(c) (_ sprite: OpaquePointer?) -> Void)?
        ) {
            sprite.setUpdateFunction.unsafelyUnwrapped(pointer, updateFunction)
        }

        /// Sets the draw function for the sprite. Note that the callback is only called when the
        /// sprite is on screen and has a size specified via ``setSize(width:height:)`` or ``bounds``.
        public func setDrawFunction(
            drawFunction: (@convention(c) (
                _ sprite: OpaquePointer?,
                _ bounds: PDRect,
                _ drawRect: PDRect
            ) -> Void)?
        ) {
            sprite.setDrawFunction.unsafelyUnwrapped(pointer, drawFunction)
        }

        /// Adds the sprite to the display list, so that it is drawn in the current scene.
        public func addToDisplayList() {
            sprite.addSprite.unsafelyUnwrapped(pointer)
        }

        /// Removes the given sprite from the display list.
        public func removeFromDisplayList() {
            sprite.removeSprite.unsafelyUnwrapped(pointer)
        }

        /// Set a callback that returns a `SpriteCollisionResponseType` for a collision between `sprite` and other.
        public func setCollisionResponseFunction(
            function: (@convention(c) (
                _ sprite: OpaquePointer?,
                _ other: OpaquePointer?
            ) -> CollisionResponseType)?
        ) {
            sprite.setCollisionResponseFunction.unsafelyUnwrapped(pointer, function)
        }

        /// Returns the same values as `moveWithCollisions()` but does not actually move the sprite.
        public func checkCollisions(goalX: Float, goalY: Float) -> CollisionInfo {
            var actualX: Float = 0, actualY: Float = 0
            var length: CInt = 0
            let collisionInfo = sprite.checkCollisions.unsafelyUnwrapped(
                pointer,
                goalX,
                goalY,
                &actualX,
                &actualY,
                &length
            )
            return CollisionInfo(
                collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                actual: Point(x: actualX, y: actualY)
            )
        }

        /// Moves the given sprite towards `goal` taking collisions into account and returns an array of `SpriteCollisionInfo`.
        /// `actualX`, `actualY` are set to the sprite’s position after collisions. If no collisions occurred, this will be the same as
        /// `goalX`, `goalY`.
        public func moveWithCollisions(goal: Point<Float>) -> CollisionInfo {
            var actualX: Float = 0, actualY: Float = 0
            var length: CInt = 0
            let collisionInfo = sprite.moveWithCollisions.unsafelyUnwrapped(
                pointer,
                goal.x,
                goal.y,
                &actualX,
                &actualY,
                &length
            )
            return CollisionInfo(
                collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                actual: Point(x: actualX, y: actualY)
            )
        }

        // MARK: Internal

        let pointer: OpaquePointer
    }

    // MARK: - Properties

    /// Sets the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
    public static func setClipRectsInRange(clipRect: Rect<CInt>, startZ: CInt, endZ: CInt) {
        sprite.setClipRectsInRange.unsafelyUnwrapped(clipRect.lcdRect, startZ, endZ)
    }

    /// Clears the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
    public static func clearClipRectsInRange(startZ: CInt, endZ: CInt) {
        sprite.clearClipRectsInRange.unsafelyUnwrapped(startZ, endZ)
    }

    /// When `alwaysRedraw` is set to true, this causes all sprites to draw each frame, whether or not they have been marked dirty.
    /// This may speed up the performance of your game if the system’s dirty rect tracking is taking up too much time - for example
    /// if there are many sprites moving around on screen at once.
    public static func setAlwaysRedraw(_ alwaysRedraw: Bool) {
        sprite.setAlwaysRedraw.unsafelyUnwrapped(alwaysRedraw ? 1 : 0)
    }

    /// Marks the given dirtyRect (in screen coordinates) as needing a redraw. Graphics drawing functions now call this
    /// automatically, adding their drawn areas to the sprite’s dirty list, so there’s usually no need to call this manually.
    public static func addDirtyRect(_ dirtyRect: Rect<CInt>) {
        sprite.addDirtyRect.unsafelyUnwrapped(dirtyRect.lcdRect)
    }

    // MARK: - Display List

    /// Removes the given array of sprites from the display list.
    public static func removeSpritesFromDisplayList(_ sprites: UnsafeMutableBufferPointer<Sprite>) {
        var pointers = sprites.map { Optional($0.pointer) }
        sprite.removeSprites.unsafelyUnwrapped(&pointers, CInt(sprites.count))
    }

    /// Removes all sprites from the display list.
    public static func removeAllSpritesFromDisplayList() {
        sprite.removeAllSprites.unsafelyUnwrapped()
    }

    /// Returns the total number of sprites in the display list.
    public static func getDisplayListSpriteCount() -> CInt {
        sprite.getSpriteCount.unsafelyUnwrapped()
    }

    /// Draws every sprite in the display list.
    public static func drawDisplayListSprites() {
        sprite.drawSprites.unsafelyUnwrapped()
    }

    /// Updates and draws every sprite in the display list.
    public static func updateAndDrawDisplayListSprites() {
        sprite.updateAndDrawSprites.unsafelyUnwrapped()
    }

    // MARK: - Collisions

    /// Frees and reallocates internal collision data, resetting everything to its default state.
    public static func resetCollisionWorld() {
        sprite.resetCollisionWorld.unsafelyUnwrapped()
    }

    /// Returns an array of all sprites with collision rects containing `point`.
    /// > Warning: The caller is responsible for freeing the returned array.
    public static func querySpritesAtPoint(_ point: Point<Float>) -> UnsafeBufferPointer<OpaquePointer?> {
        var length: CInt = 0
        let sprites = sprite.querySpritesAtPoint.unsafelyUnwrapped(point.x, point.y, &length)
        return UnsafeBufferPointer(start: sprites, count: Int(length))
    }

    /// Returns an array of all sprites with collision rects that intersect `rect`.
    /// > Warning: The caller is responsible for freeing the returned array.
    public static func querySpritesInRect(_ rect: Rect<Float>) -> UnsafeBufferPointer<OpaquePointer?> {
        var length: CInt = 0
        let sprites = sprite.querySpritesInRect.unsafelyUnwrapped(
            rect.x,
            rect.y,
            rect.width,
            rect.height,
            &length
        )
        return UnsafeBufferPointer(start: sprites, count: Int(length))
    }

    /// Returns an array of all sprites with collision rects that intersect `line`.
    /// > Warning: The caller is responsible for freeing the returned array.
    public static func querySpritesAlongLine(_ line: Line<Float>) -> UnsafeBufferPointer<OpaquePointer?> {
        var length: CInt = 0
        let sprites = sprite.querySpritesAlongLine.unsafelyUnwrapped(
            line.start.x,
            line.start.y,
            line.end.x,
            line.end.y,
            &length
        )
        return UnsafeBufferPointer(start: sprites, count: Int(length))
    }

    /// Returns an array of `SpriteQueryInfo` for all sprites with collision rects that intersect `line`.
    /// If you don’t need this information, use `querySpritesAlongLine()` as it will be faster.
    public static func querySpriteInfoAlongLine(_ line: Line<Float>) -> QueryInfo {
        var length: CInt = 0
        let spriteInfo = sprite.querySpriteInfoAlongLine.unsafelyUnwrapped(
            line.start.x,
            line.start.y,
            line.end.x,
            line.end.y,
            &length
        )
        return QueryInfo(info: UnsafeBufferPointer(start: spriteInfo, count: Int(length)))
    }

    /// Returns an array of all sprites that have collide rects that are currently overlapping. Each consecutive pair of sprites is overlapping
    /// (eg. 0 & 1 overlap, 2 & 3 overlap, etc).
    /// > Warning: The caller is responsible for freeing the returned array.
    public static func allOverlappingSprites() -> UnsafeBufferPointer<OpaquePointer?> {
        var length: CInt = 0
        let sprites = sprite.allOverlappingSprites.unsafelyUnwrapped(&length)
        return UnsafeBufferPointer(start: sprites, count: Int(length))
    }

    // MARK: Private

    private static var sprite: playdate_sprite { Playdate.playdateAPI.sprite.pointee }
}
