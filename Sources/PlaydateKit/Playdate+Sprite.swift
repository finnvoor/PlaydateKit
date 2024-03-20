public import CPlaydate

public extension Playdate {
    enum Sprite {
        // MARK: Public

        public typealias Rect = PDRect
        public typealias CollisionResponseType = SpriteCollisionResponseType

        public class CollisionInfo {
            // MARK: Lifecycle

            init(collisions: UnsafeBufferPointer<SpriteCollisionInfo>, actualX: Float, actualY: Float) {
                self.collisions = collisions
                self.actualX = actualX
                self.actualY = actualY
            }

            deinit { collisions.deallocate() }

            // MARK: Public

            public let collisions: UnsafeBufferPointer<SpriteCollisionInfo>
            public let actualX: Float
            public let actualY: Float
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
                pointer = sprite.newSprite().unsafelyUnwrapped
            }

            init(pointer: OpaquePointer) {
                self.pointer = pointer
            }

            deinit { sprite.freeSprite(pointer) }

            // MARK: Public

            /// Gets the current position of sprite.
            public var position: (x: Float, y: Float) {
                var x: Float = 0, y: Float = 0
                sprite.getPosition(pointer, &x, &y)
                return (x, y)
            }

            /// Gets/sets the bounds of the sprite.
            public var bounds: Rect {
                get { sprite.getBounds(pointer) }
                set { sprite.setBounds(pointer, newValue) }
            }

            /// Gets/sets the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width.
            /// Default is 0.5, 0.5 (the center of the sprite).
            /// This means that when you call `moveTo(x, y)`, the center of your sprite will be positioned at x, y.
            /// If you want x and y to represent the upper left corner of your sprite, specify the center as 0, 0.
            public var center: (x: Float, y: Float) {
                get {
                    var x: Float = 0, y: Float = 0
                    sprite.getCenter(pointer, &x, &y)
                    return (x, y)
                } set {
                    sprite.setCenter(pointer, newValue.x, newValue.y)
                }
            }

            /// Returns the `Bitmap` currently assigned to the given sprite.
            public var image: Graphics.Bitmap? {
                sprite.getImage(pointer).map { Graphics.Bitmap(pointer: $0) }
            }

            /// Gets/sets the Z order of the given sprite. Higher Z sprites are drawn on top of those with lower Z order.
            public var zIndex: Int16 {
                get { sprite.getZIndex(pointer) }
                set { sprite.setZIndex(pointer, newValue) }
            }

            /// Gets/sets the tag of the given sprite. This can be useful for identifying sprites or types of sprites when using the collision API.
            public var tag: UInt8 {
                get { sprite.getTag(pointer) }
                set { sprite.setTag(pointer, newValue) }
            }

            /// Flips the bitmap.
            public var imageFlip: Graphics.Bitmap.Flip {
                get { sprite.getImageFlip(pointer) }
                set { sprite.setImageFlip(pointer, newValue) }
            }

            /// Get/set the `updatesEnabled` flag of the sprite (determines whether the sprite has its update function called).
            public var updatesEnabled: Bool {
                get { sprite.updatesEnabled(pointer) != 0 }
                set { sprite.setUpdatesEnabled(pointer, newValue ? 1 : 0) }
            }

            /// Set the `visible` flag of the sprite (determines whether the sprite has its draw function called).
            public var isVisible: Bool {
                get { sprite.isVisible(pointer) != 0 }
                set { sprite.setVisible(pointer, newValue ? 1 : 0) }
            }

            /// Gets/sets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.
            public var userdata: UnsafeMutableRawPointer? {
                get { sprite.getUserdata(pointer) }
                set { sprite.setUserdata(pointer, newValue) }
            }

            /// Get/set the `collisionsEnabled` flag of the sprite (along with the `collideRect`, this
            /// determines whether the sprite participates in collisions). Set to true by default.
            public var collisionsEnabled: Bool {
                get { sprite.collisionsEnabled(pointer) != 0 }
                set { sprite.setCollisionsEnabled(pointer, newValue ? 1 : 0) }
            }

            /// Marks the area of the given sprite, relative to its bounds, to be checked for collisions with other sprites' collide rects.
            public var collideRect: Rect? {
                get { sprite.getCollideRect(pointer) }
                set {
                    if let newValue {
                        sprite.setCollideRect(pointer, newValue)
                    } else {
                        sprite.clearCollideRect(pointer)
                    }
                }
            }

            /// Returns an array of sprites that have collide rects that are currently overlapping the given sprite’s collide rect.
            /// > Warning: The caller is responsible for freeing the returned array.
            public var overlappingSprites: UnsafeBufferPointer<OpaquePointer?> {
                // TODO: - Return array of sprites? figure out memory management
                var length: CInt = 0
                let sprites = sprite.overlappingSprites(pointer, &length)
                return UnsafeBufferPointer(start: sprites, count: Int(length))
            }

            /// Allocates and returns a copy of the sprite.
            public func copy() -> Sprite {
                Sprite(pointer: sprite.copy(pointer).unsafelyUnwrapped)
            }

            /// Moves the sprite to `x`, `y` and resets its bounds based on the bitmap dimensions and center.
            public func moveTo(x: Float, y: Float) {
                sprite.moveTo(pointer, x, y)
            }

            /// Moves the sprite to by offsetting its current position by `dx`, `dy`.
            public func moveBy(dx: Float, dy: Float) {
                sprite.moveBy(pointer, dx, dy)
            }

            /// Sets the sprite's image to the given bitmap.
            public func setImage(image: Graphics.Bitmap, flip: Graphics.Bitmap.Flip = .bitmapUnflipped) {
                sprite.setImage(pointer, image.pointer, flip)
            }

            /// Sets the size. The size is used to set the sprite’s bounds when calling `moveTo()`.
            public func setSize(width: Float, height: Float) {
                sprite.setSize(pointer, width, height)
            }

            /// Sets the mode for drawing the sprite’s bitmap.
            public func setDrawMode(_ drawMode: Graphics.Bitmap.DrawMode) {
                sprite.setDrawMode(pointer, drawMode)
            }

            /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn.
            /// Pass `nil` to clear the sprite’s stencil.
            public func setStencil(_ stencil: Graphics.Bitmap?) {
                if let stencil {
                    sprite.setStencil(pointer, stencil.pointer)
                } else {
                    sprite.clearStencil(pointer)
                }
            }

            /// Specifies a stencil image to be set on the frame buffer before the sprite is drawn. If `tile` is set, the stencil will be tiled.
            /// Tiled stencils must have width evenly divisible by 32.
            public func setStencilImage(_ stencil: Graphics.Bitmap, tile: CInt) {
                sprite.setStencilImage(pointer, stencil.pointer, tile)
            }

            /// Sets the sprite’s stencil to the given pattern.
            public func setStencilPattern(_ pattern: UnsafeMutablePointer<UInt8>) {
                sprite.setStencilPattern(pointer, pattern)
            }

            /// Sets the clipping rectangle for sprite drawing.
            /// Pass `nil` to clear the sprite’s clipping rectangle.
            public func setClipRect(_ clipRect: Graphics.Rect?) {
                if let clipRect {
                    sprite.setClipRect(pointer, clipRect)
                } else {
                    sprite.clearClipRect(pointer)
                }
            }

            /// Marking a sprite opaque tells the sprite system that it doesn’t need to draw anything underneath the sprite,
            /// since it will be overdrawn anyway. If you set an image without a mask/alpha channel on the sprite, it automatically
            /// sets the `opaque` flag.
            public func setOpaque(_ opaque: Bool) {
                sprite.setOpaque(pointer, opaque ? 1 : 0)
            }

            /// Forces the sprite to redraw.
            public func markDirty() {
                sprite.markDirty(pointer)
            }

            /// When `ignoresDrawOffset` is set to true, the sprite will draw in screen coordinates, ignoring the currently-set drawOffset.
            ///
            /// This only affects drawing, and should not be used on sprites being used for collisions, which will still happen in world-space.
            public func setIgnoresDrawOffset(_ ignoresDrawOffset: Bool) {
                sprite.setIgnoresDrawOffset(pointer, ignoresDrawOffset ? 1 : 0)
            }

            /// Sets the update function for the sprite.
            public func setUpdateFunction(
                _ updateFunction: (@convention(c) (_ sprite: OpaquePointer?) -> Void)?
            ) {
                sprite.setUpdateFunction(pointer, updateFunction)
            }

            /// Sets the draw function for the sprite. Note that the callback is only called when the
            /// sprite is on screen and has a size specified via `setSize()` or `setBounds()`.
            public func setDrawFunction(
                drawFunction: (@convention(c) (
                    _ sprite: OpaquePointer?,
                    _ bounds: Rect,
                    _ drawRect: Rect
                ) -> Void)?
            ) {
                sprite.setDrawFunction(pointer, drawFunction)
            }

            /// Adds the sprite to the display list, so that it is drawn in the current scene.
            public func addToDisplayList() {
                sprite.addSprite(pointer)
            }

            /// Removes the given sprite from the display list.
            public func removeFromDisplayList() {
                sprite.removeSprite(pointer)
            }

            /// Set a callback that returns a `SpriteCollisionResponseType` for a collision between `sprite` and other.
            public func setCollisionResponseFunction(
                function: (@convention(c) (
                    _ sprite: OpaquePointer?,
                    _ other: OpaquePointer?
                ) -> CollisionResponseType)?
            ) {
                sprite.setCollisionResponseFunction(pointer, function)
            }

            /// Returns the same values as `moveWithCollisions()` but does not actually move the sprite.
            public func checkCollisions(goalX: Float, goalY: Float) -> CollisionInfo {
                var actualX: Float = 0, actualY: Float = 0
                var length: CInt = 0
                let collisionInfo = sprite.checkCollisions(pointer, goalX, goalY, &actualX, &actualY, &length)
                return CollisionInfo(
                    collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                    actualX: actualX,
                    actualY: actualY
                )
            }

            /// Moves the given sprite towards `goalX`, `goalY` taking collisions into account and returns an array of `SpriteCollisionInfo`.
            /// `actualX`, `actualY` are set to the sprite’s position after collisions. If no collisions occurred, this will be the same as
            /// `goalX`, `goalY`.
            public func moveWithCollisions(goalX: Float, goalY: Float) -> CollisionInfo {
                var actualX: Float = 0, actualY: Float = 0
                var length: CInt = 0
                let collisionInfo = sprite.moveWithCollisions(pointer, goalX, goalY, &actualX, &actualY, &length)
                return CollisionInfo(
                    collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                    actualX: actualX,
                    actualY: actualY
                )
            }

            // MARK: Internal

            let pointer: OpaquePointer
        }

        // MARK: - Properties

        /// Sets the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
        public static func setClipRectsInRange(clipRect: Graphics.Rect, startZ: CInt, endZ: CInt) {
            sprite.setClipRectsInRange(clipRect, startZ, endZ)
        }

        /// Clears the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
        public static func clearClipRectsInRange(startZ: CInt, endZ: CInt) {
            sprite.clearClipRectsInRange(startZ, endZ)
        }

        /// When `alwaysRedraw` is set to true, this causes all sprites to draw each frame, whether or not they have been marked dirty.
        /// This may speed up the performance of your game if the system’s dirty rect tracking is taking up too much time - for example
        /// if there are many sprites moving around on screen at once.
        public static func setAlwaysRedraw(_ alwaysRedraw: Bool) {
            sprite.setAlwaysRedraw(alwaysRedraw ? 1 : 0)
        }

        /// Marks the given dirtyRect (in screen coordinates) as needing a redraw. Graphics drawing functions now call this
        /// automatically, adding their drawn areas to the sprite’s dirty list, so there’s usually no need to call this manually.
        public static func addDirtyRect(_ dirtyRect: Graphics.Rect) {
            sprite.addDirtyRect(dirtyRect)
        }

        // MARK: - Display List

        /// Removes the given array of sprites from the display list.
        public static func removeSpritesFromDisplayList(_ sprites: UnsafeMutableBufferPointer<Sprite>) {
            var pointers = sprites.map { Optional($0.pointer) }
            sprite.removeSprites(&pointers, CInt(sprites.count))
        }

        /// Removes all sprites from the display list.
        public static func removeAllSpritesFromDisplayList() {
            sprite.removeAllSprites()
        }

        /// Returns the total number of sprites in the display list.
        public static func getDisplayListSpriteCount() -> CInt {
            sprite.getSpriteCount()
        }

        /// Draws every sprite in the display list.
        public static func drawDisplayListSprites() {
            sprite.drawSprites()
        }

        /// Updates and draws every sprite in the display list.
        public static func updateAndDrawDisplayListSprites() {
            sprite.updateAndDrawSprites()
        }

        // MARK: - Collisions

        /// Frees and reallocates internal collision data, resetting everything to its default state.
        public static func resetCollisionWorld() {
            sprite.resetCollisionWorld()
        }

        /// Returns an array of all sprites with collision rects containing the point at `x`, `y`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesAtPoint(x: Float, y: Float) -> UnsafeBufferPointer<OpaquePointer?> {
            var length: CInt = 0
            let sprites = sprite.querySpritesAtPoint(x, y, &length)
            return UnsafeBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of all sprites with collision rects that intersect the `width` by `height` rect at `x`, `y`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesInRect(x: Float, y: Float, width: Float, height: Float) -> UnsafeBufferPointer<OpaquePointer?> {
            var length: CInt = 0
            let sprites = sprite.querySpritesInRect(x, y, width, height, &length)
            return UnsafeBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of all sprites with collision rects that intersect the line connecting `x1`, `y1` and `x2`, `y2`.
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func querySpritesAlongLine(x1: Float, y1: Float, x2: Float, y2: Float) -> UnsafeBufferPointer<OpaquePointer?> {
            var length: CInt = 0
            let sprites = sprite.querySpritesAlongLine(x1, y1, x2, y2, &length)
            return UnsafeBufferPointer(start: sprites, count: Int(length))
        }

        /// Returns an array of `SpriteQueryInfo` for all sprites with collision rects that intersect the line connecting `x1`, `y1` and `x2`, `y2`.
        /// If you don’t need this information, use `querySpritesAlongLine()` as it will be faster.
        public static func querySpriteInfoAlongLine(x1: Float, y1: Float, x2: Float, y2: Float) -> QueryInfo {
            var length: CInt = 0
            let spriteInfo = sprite.querySpriteInfoAlongLine(x1, y1, x2, y2, &length)
            return QueryInfo(info: UnsafeBufferPointer(start: spriteInfo, count: Int(length)))
        }

        /// Returns an array of all sprites that have collide rects that are currently overlapping. Each consecutive pair of sprites is overlapping
        /// (eg. 0 & 1 overlap, 2 & 3 overlap, etc).
        /// > Warning: The caller is responsible for freeing the returned array.
        public static func allOverlappingSprites() -> UnsafeBufferPointer<OpaquePointer?> {
            var length: CInt = 0
            let sprites = sprite.allOverlappingSprites(&length)
            return UnsafeBufferPointer(start: sprites, count: Int(length))
        }

        // MARK: Private

        private static var sprite: playdate_sprite { playdateAPI.sprite.pointee }
    }
}
