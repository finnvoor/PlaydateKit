import CPlaydate

public extension Sound {
    class Sequence {
        // MARK: Lifecycle

        public init() {
            pointer = sequence.newSequence.unsafelyUnwrapped().unsafelyUnwrapped
        }

        deinit {
            stop() // simulator crashes without this
            sequence.freeSequence.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public private(set) var tracks: [Track] = []

        public var isPlaying: Bool {
            sequence.isPlaying.unsafelyUnwrapped(pointer) == 1
        }

        public var time: Int {
            get { Int(sequence.getTime.unsafelyUnwrapped(pointer)) }
            set { sequence.setTime.unsafelyUnwrapped(pointer, UInt32(newValue)) }
        }

        public var tempo: Float {
            get { sequence.getTempo.unsafelyUnwrapped(pointer) }
            set { sequence.setTempo.unsafelyUnwrapped(pointer, newValue) }
        }

        public var length: Int {
            Int(sequence.getLength.unsafelyUnwrapped(pointer))
        }

        public var trackCount: Int {
            Int(sequence.getTrackCount.unsafelyUnwrapped(pointer))
        }

        public func loadMIDIFile(path: String) -> Bool {
            sequence.loadMIDIFile.unsafelyUnwrapped(pointer, path) == 1
        }

        public func play(finishCallback: (() -> Void)? = nil) {
            self.finishCallback = finishCallback
            sequence.play.unsafelyUnwrapped(pointer, { _, userdata in
                let sequence = Unmanaged<Sequence>.fromOpaque(userdata.unsafelyUnwrapped).takeUnretainedValue()
                sequence.finishCallback?()
                sequence.finishCallback = nil
            }, Unmanaged.passUnretained(self).toOpaque())
        }

        public func stop() {
            sequence.stop.unsafelyUnwrapped(pointer)
        }
        
        public func setLoops(_ loops: Int = 0, startStep: Int = 0, endStep: Int) {
            sequence.setLoops.unsafelyUnwrapped(
                pointer,
                Int32(startStep),
                Int32(endStep),
                Int32(loops)
            )
        }

        @discardableResult public func addTrack() -> Track {
            let trackPointer = sequence.addTrack.unsafelyUnwrapped(pointer).unsafelyUnwrapped
            let track = Track(pointer: trackPointer, free: false)
            tracks.append(track)
            return track
        }

        public func allNotesOff() {
            sequence.allNotesOff.unsafelyUnwrapped(pointer)
        }

        public func getCurrentStep() -> (currentStep: Int, timeOffset: Int) {
            var timeOffset: Int32 = 0
            let currentStep = sequence.getCurrentStep.unsafelyUnwrapped(pointer, &timeOffset)
            return (Int(currentStep), Int(timeOffset))
        }

        public func setCurrentStep(
            _ step: Int,
            timeOffset: Int? = nil,
            playNotes: Bool = false
        ) {
            sequence.setCurrentStep.unsafelyUnwrapped(
                pointer,
                Int32(step),
                Int32(timeOffset ?? 0),
                playNotes ? 1 : 0
            )
        }

        // MARK: Private

        private let pointer: OpaquePointer
        private var finishCallback: (() -> Void)?
    }
}
