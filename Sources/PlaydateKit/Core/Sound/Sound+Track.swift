import CPlaydate

public extension Sound {
    class Track {
        // MARK: Lifecycle

        init(pointer: OpaquePointer, free: Bool = true) {
            self.pointer = pointer
            self.free = free
        }

        public init() {
            pointer = track.newTrack.unsafelyUnwrapped().unsafelyUnwrapped
            free = true
        }

        deinit {
            if free {
                track.freeTrack.unsafelyUnwrapped(pointer)
            }
        }

        // MARK: Public

        public var instrument: Instrument? {
            didSet {
                track.setInstrument.unsafelyUnwrapped(pointer, instrument?.pointer)
            }
        }

        public var length: Int {
            Int(track.getLength.unsafelyUnwrapped(pointer))
        }

        public var activeVoiceCount: Int {
            Int(track.activeVoiceCount.unsafelyUnwrapped(pointer))
        }

        public var polyphony: Int {
            Int(track.getPolyphony.unsafelyUnwrapped(pointer))
        }

        public func addNoteEvent(
            step: Int,
            note: MIDINote = MIDINote(NOTE_C4),
            length: Int = 1,
            velocity: Float = 1
        ) {
            track.addNoteEvent.unsafelyUnwrapped(
                pointer,
                UInt32(step),
                UInt32(length),
                note,
                velocity
            )
        }

        public func removeNoteEvent(
            step: Int,
            note: MIDINote = MIDINote(NOTE_C4)
        ) {
            track.removeNoteEvent.unsafelyUnwrapped(
                pointer,
                UInt32(step),
                note
            )
        }

        public func clearNotes() {
            track.clearNotes.unsafelyUnwrapped(pointer)
        }

        public func note(at step: Int) -> (
            note: MIDINote,
            length: Int,
            velocity: Float
        )? {
            let index = track.getIndexForStep.unsafelyUnwrapped(pointer, UInt32(step))
            var outStep: UInt32 = 0
            var note: MIDINote = 0
            var length: UInt32 = 0
            var velocity: Float = 0
            guard track.getNoteAtIndex.unsafelyUnwrapped(
                pointer,
                index,
                &outStep,
                &length,
                &note,
                &velocity
            ) == 1, outStep == step else {
                return nil
            }
            return (note, Int(length), velocity)
        }

        public func setMuted(_ muted: Bool = true) {
            track.setMuted.unsafelyUnwrapped(pointer, muted ? 1 : 0)
        }

        // MARK: Internal

        let pointer: OpaquePointer

        // MARK: Private

        private let free: Bool
    }
}
