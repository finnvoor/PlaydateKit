@preconcurrency public import CPlaydate

public extension Playdate {
    enum Sprite {
        private static var sprite: playdate_sprite { playdateAPI.sprite.pointee }
    }
}
