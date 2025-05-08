import CPlaydate

public extension Sound {
    class Instrument: Source {
        // MARK: Lifecycle

        public init() {
            super.init(pointer: instrument.newInstrument.unsafelyUnwrapped().unsafelyUnwrapped)
        }

        deinit {
            instrument.freeInstrument.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public var activeVoiceCount: Int {
            Int(instrument.activeVoiceCount.unsafelyUnwrapped(pointer))
        }

        public func addVoice(
            synth: Synth,
            rangeStart: MIDINote,
            rangeEnd: MIDINote,
            transpose: Float = 0
        ) -> Bool {
            guard instrument.addVoice.unsafelyUnwrapped(
                pointer,
                synth.pointer,
                rangeStart,
                rangeEnd,
                transpose
            ) == 1 else { return false }
            voices.append(synth)
            return true
        }

        @discardableResult public func playNote(
            frequency: Float,
            velocity: Float = 1,
            length: Float = -1,
            when: CUnsignedInt = 0
        ) -> Synth {
            let synthPointer = instrument.playNote.unsafelyUnwrapped(
                pointer,
                frequency,
                velocity,
                length,
                when
            ).unsafelyUnwrapped
            return voices.first { $0.pointer == synthPointer }!
        }

        @discardableResult public func playMIDINote(
            note: MIDINote,
            velocity: Float = 1,
            length: Float = -1,
            when: CUnsignedInt = 0
        ) -> Synth {
            let synthPointer = instrument.playMIDINote.unsafelyUnwrapped(
                pointer,
                note,
                velocity,
                length,
                when
            ).unsafelyUnwrapped
            return voices.first { $0.pointer == synthPointer }!
        }

        public func noteOff(_ note: MIDINote, when: CUnsignedInt = 0) {
            instrument.noteOff.unsafelyUnwrapped(pointer, note, when)
        }

        public func setPitchBend(_ amount: Float) {
            instrument.setPitchBend.unsafelyUnwrapped(pointer, amount)
        }

        public func setPitchBendRange(_ halfSteps: Float) {
            instrument.setPitchBendRange.unsafelyUnwrapped(pointer, halfSteps)
        }

        public func setTranspose(_ halfSteps: Float) {
            instrument.setTranspose.unsafelyUnwrapped(pointer, halfSteps)
        }

        public func allNotesOff(when: CUnsignedInt = 0) {
            instrument.allNotesOff.unsafelyUnwrapped(pointer, when)
        }

        // MARK: Private

        private var voices: [Synth] = []
    }
}
