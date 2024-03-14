@preconcurrency public import CPlaydate

public extension Playdate {
    enum JSON {
        private static var json: playdate_json { playdateAPI.json.pointee }
    }
}
