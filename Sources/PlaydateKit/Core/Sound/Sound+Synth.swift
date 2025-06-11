import CPlaydate

public extension Sound {
    // MARK: Public

    class Synth: Source {
        // MARK: Lifecycle

        override init(pointer: OpaquePointer) {
            super.init(pointer: pointer)
        }

        /// Creates a new synth object to play a waveform or wavetable. See ``Sound/Synth/setWaveform(_:)`` for waveform values.
        public init() {
            super.init(pointer: synth.newSynth.unsafelyUnwrapped().unsafelyUnwrapped)
        }

        deinit {
            synth.freeSynth.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public internal(set) var frequencyModulator: Signal? = nil

        public internal(set) var amplitudeModulator: Signal? = nil

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

        public func setSample(_ sample: Sample, sustainStart: Int = 0, sustainEnd: Int = 0) {
            synth.setSample.unsafelyUnwrapped(pointer, sample.pointer, UInt32(sustainStart), UInt32(sustainEnd))
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

        /// Smoothly changes the envelope’s shape from linear (amount=0) to exponential (amount=1).
        public func setEnvelopeCurvature(_ amount: Float) {
            let envelopePointer = synth.getEnvelope.unsafelyUnwrapped(pointer).unsafelyUnwrapped

            envelope.setCurvature.unsafelyUnwrapped(envelopePointer, amount)
        }

        public func setTranspose(_ halfSteps: Float) {
            synth.setTranspose.unsafelyUnwrapped(pointer, halfSteps)
        }

        /// Sets a signal to modulate the synth’s frequency. The signal is scaled so that a value of 1 doubles the synth pitch (i.e. an octave up) and -1 halves it (an octave down). Set to `nil` to clear the modulator.
        public func setFrequencyModulator(_ frequencyModulator: Signal?) {
            self.frequencyModulator = frequencyModulator
            synth.setFrequencyModulator.unsafelyUnwrapped(pointer, frequencyModulator?.pointer)
        }

        /// Sets a signal to modulate the synth’s output amplitude. Set to `nil` to clear the modulator.
        public func setAmplitudeModulator(_ amplitudeModulator: Signal?) {
            self.amplitudeModulator = amplitudeModulator
            synth.setAmplitudeModulator.unsafelyUnwrapped(pointer, amplitudeModulator?.pointer)
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
            when: CUnsignedInt = 0
        ) {
            synth.playNote.unsafelyUnwrapped(pointer, frequency, volume, length, when)
        }

        public func playMIDINote(
            note: MIDINote,
            volume: Float = 1,
            length: Float = -1,
            when: CUnsignedInt = 0
        ) {
            synth.playMIDINote.unsafelyUnwrapped(pointer, note, volume, length, when)
        }

        /// Sends a note off event to the synth.
        /// - Parameter when: The scheduled time to send a note off event. Defaults to immediately.
        public func noteOff(when: CUnsignedInt = 0) {
            synth.noteOff.unsafelyUnwrapped(pointer, when)
        }

        public func setParameter(at position: Int, to value: Float) -> Bool {
            synth.setParameter.unsafelyUnwrapped(pointer, Int32(position), value) == 1
        }
    }
}
