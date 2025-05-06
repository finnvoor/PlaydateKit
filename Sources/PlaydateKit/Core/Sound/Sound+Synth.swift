import CPlaydate

public extension Sound {
    // MARK: Public

    class Synth {
        // MARK: Lifecycle

        init(pointer: OpaquePointer) {
            self.pointer = pointer
        }

        /// Creates a new synth object to play a waveform or wavetable. See ``Sound/Synth/setWaveform(_:)`` for waveform values.
        public init() {
            pointer = synth.newSynth.unsafelyUnwrapped().unsafelyUnwrapped
        }

        deinit {
            synth.freeSynth.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public var volume: (left: Float, right: Float) {
            get {
                var left: Float = 0
                var right: Float = 0
                synth.getVolume.unsafelyUnwrapped(pointer, &left, &right)
                return (left, right)
            }
            set {
                synth.setVolume.unsafelyUnwrapped(pointer, newValue.left, newValue.right)
            }
        }

        public var isPlaying: Bool {
            synth.isPlaying.unsafelyUnwrapped(pointer) == 1
        }

        public var parameterCount: Int {
            Int(synth.getParameterCount.unsafelyUnwrapped(pointer))
        }

        public func copy() -> Synth {
            let copyPointer = synth.copy.unsafelyUnwrapped(pointer).unsafelyUnwrapped
            return Synth(pointer: copyPointer)
        }

        public func setWaveform(_ waveform: SoundWaveform) {
            synth.setWaveform.unsafelyUnwrapped(pointer, waveform)
        }

        /// Sets the attack time, in seconds.
        public func setAttackTime(_ attackTime: Float) {
            synth.setAttackTime.unsafelyUnwrapped(pointer, attackTime)
        }

        /// Sets the decay time, in seconds.
        public func setDecayTime(_ decayTime: Float) {
            synth.setDecayTime.unsafelyUnwrapped(pointer, decayTime)
        }

        /// Sets the sustain level, as a proportion of the total level (0.0 to 1.0).
        public func setSustainLevel(_ sustainLevel: Float) {
            synth.setSustainLevel.unsafelyUnwrapped(pointer, sustainLevel)
        }

        /// Sets the release time, in seconds.
        public func setReleaseTime(_ releaseTime: Float) {
            synth.setReleaseTime.unsafelyUnwrapped(pointer, releaseTime)
        }

        public func clearEnvelope() {
            synth.clearEnvelope.unsafelyUnwrapped(pointer)
        }

        public func setTranspose(_ halfSteps: Float) {
            synth.setTranspose.unsafelyUnwrapped(pointer, halfSteps)
        }

        /// Plays a note with the current waveform or sample.
        /// - Parameters:
        ///   - frequency: The frequency of the note to play.
        ///   - volume: 0 to 1, defaults to 1
        ///   - length: In seconds. If omitted, note will play until you call noteOff()
        ///   - when: Seconds since the sound engine started (see ``Sound/currentTime``). Defaults to the current time.
        public func playNote(
            frequency: Float,
            volume: Float = 1,
            length: Float = -1,
            when: Int = 0
        ) {
            synth.playNote.unsafelyUnwrapped(pointer, frequency, volume, length, UInt32(when))
        }

        public func playMIDINote(
            note: MIDINote,
            volume: Float = 1,
            length: Float = -1,
            when: Int = 0
        ) {
            synth.playMIDINote.unsafelyUnwrapped(pointer, note, volume, length, UInt32(when))
        }

        /// Sends a note off event to the synth.
        /// - Parameter when: The scheduled time to send a note off event. Defaults to immediately.
        public func noteOff(when: Int = 0) {
            synth.noteOff.unsafelyUnwrapped(pointer, UInt32(when))
        }

        public func setParameter(at position: Int, to value: Float) -> Bool {
            synth.setParameter.unsafelyUnwrapped(pointer, Int32(position), value) == 1
        }

        // MARK: Internal

        let pointer: OpaquePointer
    }
}
