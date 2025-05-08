import CPlaydate

public extension Sound {
    class Channel {
        // MARK: Lifecycle

        init(pointer: OpaquePointer, free: Bool = true) {
            self.pointer = pointer
            self.free = free
        }

        public init() {
            pointer = channel.newChannel.unsafelyUnwrapped().unsafelyUnwrapped
            free = true
        }

        deinit {
            if free {
                channel.freeChannel.unsafelyUnwrapped(pointer)
            }
        }

        // MARK: Public

        public var volume: Float {
            get { channel.getVolume.unsafelyUnwrapped(pointer) }
            set { channel.setVolume.unsafelyUnwrapped(pointer, newValue) }
        }

        public func addSource(_ source: Source) -> CInt {
            channel.addSource.unsafelyUnwrapped(pointer, source.pointer)
        }

        public func removeSource(_ source: Source) -> CInt {
            channel.removeSource.unsafelyUnwrapped(pointer, source.pointer)
        }

        public func setPan(_ pan: Float) {
            channel.setPan.unsafelyUnwrapped(pointer, pan)
        }

        // MARK: Internal

        let pointer: OpaquePointer

        // MARK: Private

        private let free: Bool
    }
}
