import CPlaydate

public extension Sound {
    // MARK: Public

    class LFO: Signal {
        // MARK: Lifecycle

        /// Returns a new LFO object, which can be used to modulate sounds. See ``Sound/LFO/setType(_:)`` for type values.
        public init(type: LFOType) {
            super.init(pointer: lfo.newLFO.unsafelyUnwrapped(type).unsafelyUnwrapped, free: false)
        }

        deinit {
            lfo.freeLFO.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        /// Return the current output value of the LFO.
        override public var value: Float {
            lfo.getValue.unsafelyUnwrapped(pointer)
        }

        public func setType(_ type: LFOType) {
            lfo.setType.unsafelyUnwrapped(pointer, type)
        }

        /// Sets the LFO’s rate, in cycles per second.
        public func setRate(_ rate: Float) {
            lfo.setRate.unsafelyUnwrapped(pointer, rate)
        }

        /// Sets the LFO’s phase, from 0 to 1.
        public func setPhase(_ phase: Float) {
            lfo.setPhase.unsafelyUnwrapped(pointer, phase)
        }

        /// Sets the LFO’s initial phase, from 0 to 1.
        public func setStartPhase(_ startPhase: Float) {
            lfo.setStartPhase.unsafelyUnwrapped(pointer, startPhase)
        }

        /// Sets the center value for the LFO.
        public func setCenter(_ center: Float) {
            lfo.setCenter.unsafelyUnwrapped(pointer, center)
        }

        /// Sets the depth of the LFO.
        public func setDepth(_ depth: Float) {
            lfo.setDepth.unsafelyUnwrapped(pointer, depth)
        }

        /// Sets the LFO type to arpeggio, where the given values are in half-steps from the center note. For example, the sequence (0, 4, 7, 12) plays the notes of a major chord.
        public func setArpeggiation(_ steps: [Float]) {
            let length = steps.count

            steps.withUnsafeBufferPointer { buf in
                lfo.setArpeggiation.unsafelyUnwrapped(
                    pointer,
                    Int32(buf.count),
                    UnsafeMutablePointer(mutating: buf.baseAddress!)
                )
            }
        }

        /// Sets an initial holdoff time for the LFO where the LFO remains at its center value, and a ramp time where the value increases linearly to its maximum depth. Values are in seconds.
        public func setDelay(holdoff: Float, ramptime: Float) {
            lfo.setDelay.unsafelyUnwrapped(pointer, holdoff, ramptime)
        }

        /// If retrigger is on, the LFO’s phase is reset to its initial phase (default 0) when a synth using the LFO starts playing a note.
        public func setRetrigger(_ retrigger: Bool) {
            lfo.setRetrigger.unsafelyUnwrapped(pointer, retrigger ? 1 : 0)
        }

        /// If `global` is set, the LFO is continuously updated whether or not it’s currently in use.
        public func setGlobal(_ global: Bool) {
            lfo.setGlobal.unsafelyUnwrapped(pointer, global ? 1 : 0)
        }
    }
}
