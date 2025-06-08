import CPlaydate

public extension Sound {
    class Signal {
        // MARK: Lifecycle

        init(pointer: OpaquePointer) {
            self.pointer = pointer
        }

        deinit {
            signal.freeSignal.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public var value: Float {
            signal.getValue.unsafelyUnwrapped(pointer)
        }

        /// Offsets the signal’s output by the given amount.
        public func setValueOffset(_ offset: Float) {
            signal.setValueOffset.unsafelyUnwrapped(pointer, offset)
        }

        /// Scales the signal’s output by the given factor. The scale is applied before the offset.
        public func setValueScale(_ scale: Float) {
            signal.setValueScale.unsafelyUnwrapped(pointer, scale)
        }

        // MARK: Internal

        let pointer: OpaquePointer
    }
}
