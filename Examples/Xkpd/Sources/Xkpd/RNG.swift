import PlaydateKit

class RNG: RandomNumberGenerator {
    static nonisolated(unsafe) var instance = RNG(seed: UInt64(System.secondsSinceEpoch))

    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
