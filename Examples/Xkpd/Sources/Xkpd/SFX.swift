import PlaydateKit

class SFX {
    // MARK: Lifecycle

    private init() {
        samplePlayers = [
            .comicLoaded: SFX.makeSamplePlayer(path: "sfx/comicLoaded")!,
            .dismissWindow: SFX.makeSamplePlayer(path: "sfx/dismissWindow")!,
            .error: SFX.makeSamplePlayer(path: "sfx/error")!,
            .goto: SFX.makeSamplePlayer(path: "sfx/goto")!,
            .nextComic: SFX.makeSamplePlayer(path: "sfx/nextComic")!,
            .prevComic: SFX.makeSamplePlayer(path: "sfx/prevComic")!,
            .scrollEdge: SFX.makeSamplePlayer(path: "sfx/scrollEdge")!,
            .scrolling: SFX.makeSamplePlayer(path: "sfx/scrolling")!,
            .showInfo: SFX.makeSamplePlayer(path: "sfx/showInfo")!,
        ]

        samplePlayers[.scrolling]!.setVolume(0.3)
    }

    // MARK: Internal

    enum Effect {
        case comicLoaded
        case dismissWindow
        case error
        case goto
        case nextComic
        case prevComic
        case scrollEdge
        case scrolling
        case showInfo
    }

    static nonisolated(unsafe) let instance = SFX()

    let samplePlayers: [Effect: Sound.SamplePlayer]

    func play(_ effect: Effect) {
        samplePlayers[effect]?.play()
    }

    func start(_ effect: Effect) {
        guard let effect = samplePlayers[effect] else {
            return
        }

        if effect.isPlaying {
            return
        }

        effect.play(repeat: 0)
    }

    func stop(_ effect: Effect) {
        samplePlayers[effect]?.stop()
    }

    // MARK: Private

    private static func makeSamplePlayer(path: String) -> Sound.SamplePlayer? {
        let samplePlayer = Sound.SamplePlayer()
        let didSet = samplePlayer.setSample(path: path)

        return didSet ? samplePlayer : nil
    }
}
