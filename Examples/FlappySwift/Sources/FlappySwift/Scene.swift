import PlaydateKit

class Scene: Sprite.Sprite {
    func onLoad() {
        addToDisplayList()
    }

    func onUnload() {
        Sprite.removeAllSpritesFromDisplayList()
    }
}
