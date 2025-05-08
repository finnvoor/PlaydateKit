import CPlaydate

public extension Sound {
    class Source {
        // MARK: Lifecycle

        init(pointer: OpaquePointer) {
            self.pointer = pointer
        }

        // MARK: Public

        public var volume: (left: Float, right: Float) {
            get {
                var left: Float = 0
                var right: Float = 0
                source.getVolume.unsafelyUnwrapped(pointer, &left, &right)
                return (left, right)
            }
            set {
                source.setVolume.unsafelyUnwrapped(
                    pointer,
                    newValue.left,
                    newValue.right
                )
            }
        }

        public var isPlaying: Bool {
            source.isPlaying.unsafelyUnwrapped(pointer) == 1
        }

        // MARK: Internal

        let pointer: OpaquePointer
    }
}
