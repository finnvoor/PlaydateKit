import CPlaydate

/// Functions related to sprites.
///
/// Sprites are graphic objects that can be used to represent moving entities in your games, like the player,
/// or the enemies that chase after your player. Sprites animate efficiently, and offer collision detection and
/// a host of other built-in functionality.
public enum Sprite {
    // MARK: Open

    open class Sprite: Equatable {
        // MARK: Lifecycle

        /// Allocates and returns a new Sprite.
        public init() {
            pointer = sprite.newSprite.unsafelyUnwrapped().unsafelyUnwrapped
            userdata = Unmanaged.passUnretained(self).toOpaque()
            setUpdateFunction { sprite in
                let userdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
                sprite.update()
            }
            setDrawFunction { sprite, bounds, drawRect in
                let userdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
                sprite.draw(bounds: Rect(bounds), drawRect: Rect(drawRect))
            }
            setCollisionResponseFunction { sprite, other in
                let spriteUserdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(spriteUserdata).takeUnretainedValue()
                let otherUserdata = PlaydateKit.Sprite.getUserdata(other.unsafelyUnwrapped).unsafelyUnwrapped
                let other = Unmanaged<Sprite>.fromOpaque(otherUserdata).takeUnretainedValue()
                return sprite.collisionResponse(other: other)
            }
        }

        init(
            pointer: OpaquePointer,
            image: Graphics.Bitmap?,
            stencil: Graphics.Bitmap?
        ) {
            self.pointer = pointer
            self.image = image
            self.stencil = stencil
            userdata = Unmanaged.passUnretained(self).toOpaque()
            setUpdateFunction { sprite in
                let userdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
                sprite.update()
            }
            setDrawFunction { sprite, bounds, drawRect in
                let userdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
                sprite.draw(bounds: Rect(bounds), drawRect: Rect(drawRect))
            }
            setCollisionResponseFunction { sprite, other in
                let spriteUserdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                let sprite = Unmanaged<Sprite>.fromOpaque(spriteUserdata).takeUnretainedValue()
                let otherUserdata = PlaydateKit.Sprite.getUserdata(other.unsafelyUnwrapped).unsafelyUnwrapped
                let other = Unmanaged<Sprite>.fromOpaque(otherUserdata).takeUnretainedValue()
                return sprite.collisionResponse(other: other)
            }
        }

        deinit {
            setUpdateFunction { _ in }
            setDrawFunction { _, _, _ in }
            setCollisionResponseFunction { _, _ in .freeze }
            sprite.freeSprite.unsafelyUnwrapped(pointer)
        }

        // MARK: Open

        /// Called by ``Sprite.updateAndDrawDisplayListSprites()`` before sprites are drawn. Overriding this method
        /// gives you the opportunity to perform some code upon every frame.
        open func update() {}

        /// If the sprite doesn’t have an image, the sprite’s draw function is called as needed to update the display. Note that this method
        /// is only called when the sprite is on screen and has a size specified via ``setSize(width:height:)`` or ``bounds``.
        /// > Note: This is only called when ``image`` is `nil`
        open func draw(bounds _: Rect, drawRect _: Rect) {}

        /// Override to control the type of collision response that should happen when a collision with other occurs.
        ///
        /// This method should not attempt to modify the sprites in any way. While it might be tempting to deal with
        /// collisions here, doing so will have unexpected and undesirable results. Instead, this function should return
        /// one of the collision response values as quickly as possible. If sprites need to be modified as the result of a
        /// collision, do so elsewhere, such as by inspecting the list of collisions returned by ``moveWithCollisions(goal:)``.
        /// The default collision response is freeze.
        open func collisionResponse(other _: Sprite) -> CollisionResponseType { .freeze }

        // MARK: Public

        public let pointer: OpaquePointer

        /// The sprite's stencil bitmap, if set.
        public private(set) var stencil: Graphics.Bitmap?

        /// The bitmap currently assigned to the sprite.
        /// > Note: Setting an image will override a Sprite's custom ``draw(bounds:drawRect:)`` function.
        public var image: Graphics.Bitmap? {
            didSet {
                if image != nil { setDrawFunction(nil) }
                sprite.setImage.unsafelyUnwrapped(pointer, image?.pointer, imageFlip)
                if image == nil {
                    setDrawFunction { sprite, bounds, drawRect in
                        let userdata = PlaydateKit.Sprite.getUserdata(sprite.unsafelyUnwrapped).unsafelyUnwrapped
                        let sprite = Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
                        sprite.draw(bounds: Rect(bounds), drawRect: Rect(drawRect))
                    }
                }
            }
        }

        /// Gets the current position of sprite.
        public var position: Point {
            get {
                var x: Float = 0, y: Float = 0
                sprite.getPosition.unsafelyUnwrapped(pointer, &x, &y)
                return Point(x: x, y: y)
            } set {
                bounds.x = newValue.x
                bounds.y = newValue.y
            }
        }

        /// Gets/sets the bounds of the sprite.
        public var bounds: Rect {
            get { Rect(sprite.getBounds.unsafelyUnwrapped(pointer)) }
            set { sprite.setBounds.unsafelyUnwrapped(pointer, newValue.pdRect) }
        }

        /// Gets/sets the sprite’s drawing center as a fraction (ranging from 0.0 to 1.0) of the height and width.
        /// Default is 0.5, 0.5 (the center of the sprite).
        /// This means that when you call `moveTo(x, y)`, the center of your sprite will be positioned at x, y.
        /// If you want x and y to represent the upper left corner of your sprite, specify the center as 0, 0.
        public var center: Point {
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

        /// Get/set the `collisionsEnabled` flag of the sprite (along with the `collideRect`, this
        /// determines whether the sprite participates in collisions). Set to true by default.
        public var collisionsEnabled: Bool {
            get { sprite.collisionsEnabled.unsafelyUnwrapped(pointer) != 0 }
            set { sprite.setCollisionsEnabled.unsafelyUnwrapped(pointer, newValue ? 1 : 0) }
        }

        /// Marks the area of the given sprite, relative to its bounds, to be checked for collisions with other sprites' collide rects.
        public var collideRect: Rect? {
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

        public static func == (lhs: Sprite, rhs: Sprite) -> Bool {
            lhs.pointer == rhs.pointer
        }

        /// Allocates and returns a copy of the sprite.
        public func copy() -> Sprite {
            Sprite(
                pointer: sprite.copy.unsafelyUnwrapped(pointer).unsafelyUnwrapped,
                image: image,
                stencil: stencil
            )
        }

        /// Moves the sprite to `point` and resets its bounds based on the bitmap dimensions and center.
        public func moveTo(_ point: Point) {
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
        public func setStencilImage(_ stencil: Graphics.Bitmap, tile: Int) {
            self.stencil = stencil
            sprite.setStencilImage.unsafelyUnwrapped(pointer, stencil.pointer, CInt(tile))
        }

        /// Sets the sprite’s stencil to the given pattern.
        public func setStencilPattern(_ pattern: UnsafeMutablePointer<UInt8>) {
            sprite.setStencilPattern.unsafelyUnwrapped(pointer, pattern)
            stencil = nil
        }

        /// Sets the clipping rectangle for sprite drawing.
        /// Pass `nil` to clear the sprite’s clipping rectangle.
        public func setClipRect(_ clipRect: Rect?) {
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

        /// Adds the sprite to the display list, so that it is drawn in the current scene.
        public func addToDisplayList() {
            sprite.addSprite.unsafelyUnwrapped(pointer)
        }

        /// Removes the given sprite from the display list.
        public func removeFromDisplayList() {
            sprite.removeSprite.unsafelyUnwrapped(pointer)
        }

        /// Returns the same values as `moveWithCollisions()` but does not actually move the sprite.
        public func checkCollisions(goalX: Float, goalY: Float) -> CollisionResult {
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
            return CollisionResult(
                collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                actual: Point(x: actualX, y: actualY)
            )
        }

        /// Moves the given sprite towards `goal` taking collisions into account and returns an array of `SpriteCollisionInfo`.
        /// `actualX`, `actualY` are set to the sprite’s position after collisions. If no collisions occurred, this will be the same as
        /// `goalX`, `goalY`.
        @discardableResult public func moveWithCollisions(goal: Point) -> CollisionResult {
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
            return CollisionResult(
                collisions: UnsafeBufferPointer(start: collisionInfo, count: Int(length)),
                actual: Point(x: actualX, y: actualY)
            )
        }

        // MARK: Internal

        /// Gets/sets the sprite’s userdata, an arbitrary pointer used for associating the sprite with other data.
        var userdata: UnsafeMutableRawPointer? {
            get { sprite.getUserdata.unsafelyUnwrapped(pointer) }
            set { sprite.setUserdata.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Set a callback that returns a `SpriteCollisionResponseType` for a collision between `sprite` and other.
        func setCollisionResponseFunction(
            _ function: (@convention(c) (
                _ sprite: OpaquePointer?,
                _ other: OpaquePointer?
            ) -> CollisionResponseType)?
        ) {
            sprite.setCollisionResponseFunction.unsafelyUnwrapped(pointer, function)
        }

        /// Sets the draw function for the sprite. Note that the callback is only called when the
        /// sprite is on screen and has a size specified via ``setSize(width:height:)`` or ``bounds``.
        func setDrawFunction(
            _ drawFunction: (@convention(c) (
                _ sprite: OpaquePointer?,
                _ bounds: PDRect,
                _ drawRect: PDRect
            ) -> Void)?
        ) {
            sprite.setDrawFunction.unsafelyUnwrapped(pointer, drawFunction)
        }

        /// Sets the update function for the sprite.
        func setUpdateFunction(
            _ updateFunction: (@convention(c) (_ sprite: OpaquePointer?) -> Void)?
        ) {
            sprite.setUpdateFunction.unsafelyUnwrapped(pointer, updateFunction)
        }
    }

    // MARK: Public

    public typealias CollisionResponseType = SpriteCollisionResponseType

    public class CollisionResult {
        // MARK: Lifecycle

        init(collisions: UnsafeBufferPointer<SpriteCollisionInfo>, actual: Point) {
            // Trading performance for ergonomics
            self.collisions = Array(collisions).map(CollisionInfo.init)
            collisions.deallocate()
            self.actual = actual
        }

        // MARK: Public

        public class CollisionInfo {
            // MARK: Lifecycle

            init(collisionInfo: SpriteCollisionInfo) {
                self.collisionInfo = collisionInfo
            }

            // MARK: Public

            /// The sprite being moved.
            public var sprite: Sprite {
                let userdata = PlaydateKit.Sprite.getUserdata(
                    collisionInfo.sprite.unsafelyUnwrapped
                ).unsafelyUnwrapped
                return Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
            }

            /// The sprite colliding with the sprite being moved.
            public var other: Sprite {
                let userdata = PlaydateKit.Sprite.getUserdata(
                    collisionInfo.other.unsafelyUnwrapped
                ).unsafelyUnwrapped
                return Unmanaged<Sprite>.fromOpaque(userdata).takeUnretainedValue()
            }

            /// The result of collisionResponse.
            public var responseType: SpriteCollisionResponseType {
                collisionInfo.responseType
            }

            /// True if the sprite was overlapping other when the collision started.
            /// False if it didn’t overlap but tunneled through other.
            public var overlaps: Bool {
                collisionInfo.overlaps != 0
            }

            /// A number between 0 and 1 indicating how far along the movement to the goal the collision occurred.
            public var ti: Float {
                collisionInfo.ti
            }

            /// The difference between the original coordinates and the actual ones when the collision happened.
            public var move: Point {
                Point(x: collisionInfo.move.x, y: collisionInfo.move.y)
            }

            /// The collision normal; usually -1, 0, or 1 in x and y. Use this value to determine things
            /// like if your character is touching the ground.
            public var normal: Point {
                Point(x: Float(collisionInfo.normal.x), y: Float(collisionInfo.normal.y))
            }

            /// The coordinates where the sprite started touching other.
            public var touch: Point {
                Point(x: collisionInfo.touch.x, y: collisionInfo.touch.y)
            }

            /// The rectangle the sprite occupied when the touch happened.
            public var spriteRect: Rect {
                Rect(collisionInfo.spriteRect)
            }

            /// The rectangle the colliding sprite occupied when the touch happened.
            public var otherRect: Rect {
                Rect(collisionInfo.otherRect)
            }

            // MARK: Private

            private let collisionInfo: SpriteCollisionInfo
        }

        public let collisions: [CollisionInfo]
        public let actual: Point
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

    /// Sets the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
    public static func setClipRectsInRange(clipRect: Rect, startZ: Int, endZ: Int) {
        sprite.setClipRectsInRange.unsafelyUnwrapped(clipRect.lcdRect, CInt(startZ), CInt(endZ))
    }

    /// Clears the clipping rectangle for all sprites with a Z index within `startZ` and `endZ` inclusive.
    public static func clearClipRectsInRange(startZ: Int, endZ: Int) {
        sprite.clearClipRectsInRange.unsafelyUnwrapped(CInt(startZ), CInt(endZ))
    }

    /// When `alwaysRedraw` is set to true, this causes all sprites to draw each frame, whether or not they have been marked dirty.
    /// This may speed up the performance of your game if the system’s dirty rect tracking is taking up too much time - for example
    /// if there are many sprites moving around on screen at once.
    public static func setAlwaysRedraw(_ alwaysRedraw: Bool) {
        sprite.setAlwaysRedraw.unsafelyUnwrapped(alwaysRedraw ? 1 : 0)
    }

    /// Marks the given dirtyRect (in screen coordinates) as needing a redraw. Graphics drawing functions now call this
    /// automatically, adding their drawn areas to the sprite’s dirty list, so there’s usually no need to call this manually.
    public static func addDirtyRect(_ dirtyRect: Rect) {
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
    public static func getDisplayListSpriteCount() -> Int {
        Int(sprite.getSpriteCount.unsafelyUnwrapped())
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
    public static func querySpritesAtPoint(_ point: Point) -> UnsafeBufferPointer<OpaquePointer?> {
        var length: CInt = 0
        let sprites = sprite.querySpritesAtPoint.unsafelyUnwrapped(point.x, point.y, &length)
        return UnsafeBufferPointer(start: sprites, count: Int(length))
    }

    /// Returns an array of all sprites with collision rects that intersect `rect`.
    /// > Warning: The caller is responsible for freeing the returned array.
    public static func querySpritesInRect(_ rect: Rect) -> UnsafeBufferPointer<OpaquePointer?> {
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
    public static func querySpritesAlongLine(_ line: Line) -> UnsafeBufferPointer<OpaquePointer?> {
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
    public static func querySpriteInfoAlongLine(_ line: Line) -> QueryInfo {
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

    // MARK: Internal

    static func getUserdata(_ sprite: OpaquePointer) -> UnsafeMutableRawPointer? {
        Self.sprite.getUserdata(sprite)
    }

    // MARK: Private

    private static var sprite: playdate_sprite { Playdate.playdateAPI.sprite.pointee }
}
