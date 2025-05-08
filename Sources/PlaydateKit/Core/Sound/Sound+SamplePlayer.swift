import CPlaydate

public extension Sound {
    // MARK: Public

    class SamplePlayer: Source {
        // MARK: Lifecycle

        /// Creates a new SamplePlayer.
        public init() {
            super.init(pointer: sampleplayer.newPlayer.unsafelyUnwrapped().unsafelyUnwrapped)
        }

        deinit {
            if let samplePointer {
                sample.freeSample(samplePointer)
            }
            sampleplayer.freePlayer.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        /// Assigns sample to player.
        @discardableResult public func setSample(path: String) -> Bool {
            if let samplePointer {
                sample.freeSample(samplePointer)
            }

            samplePointer = sample.load(path)
            guard samplePointer != nil else { return false }

            sampleplayer.setSample(pointer, samplePointer)
            return true
        }

        /// Stops playing the sample.
        public func stop() {
            sampleplayer.stop.unsafelyUnwrapped(pointer)
        }

        /// Returns the length, in seconds, of the sample assigned to player.
        public func getLength() -> Float {
            sampleplayer.getLength.unsafelyUnwrapped(pointer)
        }

        /// Starts playing the sample in player.
        ///
        /// If repeat is greater than one, it loops the given number of times. If zero, it loops endlessly until it is stopped with /// playdate->sound->sampleplayer->stop(). If negative one, it does ping-pong looping.
        ///
        /// rate is the playback rate for the sample; 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an /// octave, etc.
        ///
        /// Returns `true` on success (which is always, currently).
        @discardableResult public func play(repeat: Int32 = 1, rate: Float = 1.0) -> Bool {
            sampleplayer.play.unsafelyUnwrapped(pointer, `repeat`, rate) == 1
        }

        /// Sets a function to be called when playback has completed.
        public func setFinishCallback(
            callback: @convention(c) (
                _ soundSource: OpaquePointer?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            soundUserdata: UnsafeMutableRawPointer? = nil
        ) {
            sampleplayer.setFinishCallback.unsafelyUnwrapped(pointer, callback, soundUserdata)
        }

        /// Sets the current offset of the SamplePlayer, in seconds.
        public func setOffset(_ offset: Float) {
            sampleplayer.setOffset.unsafelyUnwrapped(pointer, offset)
        }

        /// Returns the current offset in seconds for player.
        public func getOffset() -> Float {
            sampleplayer.getOffset.unsafelyUnwrapped(pointer)
        }

        /// When used with a repeat of -1, does ping-pong looping, with a start and end position in frames.
        public func setPlayRange(start: Int32, end: Int32) {
            sampleplayer.setPlayRange.unsafelyUnwrapped(pointer, start, end)
        }

        /// Pauses or resumes playback.
        public func setPaused(_ paused: Bool = true) {
            sampleplayer.setPaused(pointer, paused ? 1 : 0)
        }

        /// Sets the playback rate for the player. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.
        /// A negative rate produces backwards playback for PCM files, but does not work for ADPCM-encoded files.
        public func setRate(_ rate: Float) {
            sampleplayer.setRate.unsafelyUnwrapped(pointer, rate)
        }

        /// Returns the playback rate for player.
        public func getRate() -> Float {
            sampleplayer.getRate.unsafelyUnwrapped(pointer)
        }

        /// Sets the playback volume for left and right channels.
        public func setVolume(left: Float, right: Float) {
            sampleplayer.setVolume.unsafelyUnwrapped(pointer, left, right)
        }

        /// Sets the playback volume for both left and right.
        public func setVolume(_ volume: Float) {
            sampleplayer.setVolume.unsafelyUnwrapped(pointer, volume, volume)
        }

        /// Gets the current left and right channel volume of the sampleplayer.
        public func getVolume() -> (Float, Float) {
            var left: Float = 0
            var right: Float = 0
            sampleplayer.getVolume.unsafelyUnwrapped(pointer, &left, &right)
            return (left, right)
        }

        // MARK: Private

        private var samplePointer: OpaquePointer?
    }
}
