import CPlaydate

extension Sound {
    public final class CallbackSource: Source {
        // MARK: Lifecycle

        /// Registers a new callback-driven source at the default output.
        ///
        /// - Parameters:
        ///   - stereo: Whether `callback` fills both `left` and `right` buffers.
        ///   - callback: The callback function you pass in will be called every audio render cycle.
        public init?(stereo: Bool = true, callback: @escaping AudioSourceFunction) {
            let retainedBox = Unmanaged.passRetained(Box(callback))
            guard
                let pointer = Sound.sound.addSource.unsafelyUnwrapped(
                    { context, left, right, len in
                        guard let context, let left, let right else { return 0 }
                        return Unmanaged<Box>.fromOpaque(context)
                            .takeUnretainedValue()
                            .callback(left, right, len)
                    },
                    retainedBox.toOpaque(),
                    stereo ? 1 : 0
                )
            else {
                retainedBox.release()
                return nil
            }
            box = retainedBox
            super.init(pointer: pointer)
        }

        deinit {
            _ = Sound.sound.removeSource.unsafelyUnwrapped(pointer)
            box.release()
        }

        // MARK: Public

        /// This function should fill the passed-in `left` buffer (and `right` if it’s a stereo source) with `len` samples each and return `1`, or return `0` if the source is silent through the cycle.
        public typealias AudioSourceFunction = (
            _ left: UnsafeMutablePointer<Int16>,
            _ right: UnsafeMutablePointer<Int16>,
            _ len: Int32
        ) -> Int32

        // MARK: Private

        private final class Box {
            let callback: AudioSourceFunction
            init(_ callback: @escaping AudioSourceFunction) { self.callback = callback }
        }

        private let box: Unmanaged<Box>
    }
}
