import CPlaydate

public extension Sound {
    class Sample {
        // MARK: Lifecycle

        public init?(path: String) {
            guard let pointer = sample.load.unsafelyUnwrapped(path) else {
                return nil
            }

            self.pointer = pointer
        }

        deinit { sample.freeSample.unsafelyUnwrapped(pointer) }

        // MARK: Public

        public let pointer: OpaquePointer

        public func decompress() -> Bool {
            sample.decompress.unsafelyUnwrapped(pointer) == 1
        }
    }
}
