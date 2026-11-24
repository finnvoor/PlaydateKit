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

        /// Creates a sample over `byteCount` bytes of `data` in `format`, without copying them.
        ///
        /// With `freeData` false the caller keeps ownership of `data`, which must outlive this sample
        /// and every player it is assigned to. With `freeData` true the sample frees `data` when it is freed.
        public init?(
            data: UnsafeMutableRawPointer,
            format: SoundFormat,
            sampleRate: UInt32,
            byteCount: Int,
            freeData: Bool
        ) {
            guard let pointer = sample.newSampleFromData.unsafelyUnwrapped(
                data.assumingMemoryBound(to: UInt8.self),
                format,
                sampleRate,
                CInt(byteCount),
                freeData ? 1 : 0
            ) else {
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
