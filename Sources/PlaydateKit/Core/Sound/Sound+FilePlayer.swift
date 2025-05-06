import CPlaydate

public extension Sound {
    /// The fileplayer class is used for streaming audio from a file on disk. This requires less memory than keeping all of the
    /// file’s data in memory (as with the sampleplayer), but can increase overhead at run time.
    class FilePlayer {
        // MARK: Lifecycle

        /// Creates a new FilePlayer.
        public init() {
            pointer = fileplayer.newPlayer.unsafelyUnwrapped().unsafelyUnwrapped
        }

        deinit {
            fileplayer.freePlayer.unsafelyUnwrapped(pointer)
            if let callbackData = _callbackData {
                callbackData.deinitialize(count: 1)
                callbackData.deallocate()
            }
        }

        // MARK: Public

        /// Returns true if player is playing
        public var isPlaying: Bool {
            fileplayer.isPlaying.unsafelyUnwrapped(pointer) == 1
        }

        /// Installs a closure that will be called when playback has completed.
        public var finishCallback: (() -> Void)? {
            get {
                _callbackData?.pointee.callback
            }
            set {
                if let callbackData = _callbackData {
                    callbackData.pointee.callback = newValue
                } else if let newValue {
                    let callbackData: UnsafeMutablePointer<CallbackData> = .allocate(capacity: 1)
                    callbackData.initialize(to: .init(callback: newValue))
                    _callbackData = callbackData
                    setFinishCallback(
                        callback: { _, userdata in
                            if let callback = userdata?.assumingMemoryBound(to: CallbackData.self).pointee.callback {
                                callback()
                            }
                        },
                        soundUserdata: callbackData
                    )
                }
            }
        }

        /// Prepares player to stream the file at path. Returns `true` if the file exists, otherwise `false`.
        @discardableResult public func load(path: String) -> Bool {
            fileplayer.loadIntoPlayer(pointer, path) == 1
        }

        /// Starts playing the file player. If repeat is greater than one, it loops the given number of times.
        /// If zero, it loops endlessly until it is stopped with ``stop()``
        /// Returns true on success, false if buffer allocation failed.
        @discardableResult public func play(repeat: Int32 = 1) -> Bool {
            fileplayer.play.unsafelyUnwrapped(pointer, `repeat`) == 1
        }

        /// Pauses the file player.
        public func pause() {
            fileplayer.pause.unsafelyUnwrapped(pointer)
        }

        /// Stops playing the file.
        public func stop() {
            fileplayer.stop.unsafelyUnwrapped(pointer)
        }

        /// Sets the buffer length of player to bufferLen seconds;
        public func setBufferLength(bufferLength: Float) {
            fileplayer.setBufferLength.unsafelyUnwrapped(pointer, bufferLength)
        }

        /// Returns the length, in seconds, of the file loaded into player.
        public func getLength() -> Float {
            fileplayer.getLength.unsafelyUnwrapped(pointer)
        }

        /// Returns `true` if player has underrun, `false` if not.
        public func didUnderrun() -> Bool {
            fileplayer.didUnderrun.unsafelyUnwrapped(pointer) == 1
        }

        /// Sets the start and end of the loop region for playback, in seconds.
        public func setLoopRange(start: Float, end: Float) {
            fileplayer.setLoopRange.unsafelyUnwrapped(pointer, start, end)
        }

        /// Sets the current offset in seconds.
        public func setOffset(_ offset: Float) {
            fileplayer.setOffset.unsafelyUnwrapped(pointer, offset)
        }

        /// Returns the current offset in seconds for player.
        public func getOffset() -> Float {
            fileplayer.getOffset.unsafelyUnwrapped(pointer)
        }

        /// Sets the playback rate for the player. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.
        /// Unlike sampleplayers, fileplayers can’t play in reverse (i.e., rate < 0).
        public func setRate(_ rate: Float) {
            fileplayer.setRate.unsafelyUnwrapped(pointer, rate)
        }

        /// Returns the playback rate for player.
        public func getRate() -> Float {
            fileplayer.getRate.unsafelyUnwrapped(pointer)
        }

        /// If `flag` evaluates to true, the player will restart playback (after an audible stutter) as soon as data is available.
        public func setStopOnUnderrun(flag: Bool) {
            fileplayer.setStopOnUnderrun.unsafelyUnwrapped(pointer, flag ? 1 : 0)
        }

        /// Sets the playback volume for left and right channels of player.
        public func setVolume(left: Float, right: Float) {
            fileplayer.setVolume.unsafelyUnwrapped(pointer, left, right)
        }

        /// Sets the playback volume of player.
        public func setVolume(_ volume: Float) {
            fileplayer.setVolume.unsafelyUnwrapped(pointer, volume, volume)
        }

        /// Changes the volume of the fileplayer to left and right over a length of len sample frames, then calls the provided callback (if set).
        public func fadeVolume(
            left: Float,
            right: Float,
            length: Int32,
            finishCallback: @convention(c) (
                _ soundSource: OpaquePointer?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            soundUserdata: UnsafeMutableRawPointer? = nil
        ) {
            fileplayer.fadeVolume.unsafelyUnwrapped(pointer, left, right, length, finishCallback, soundUserdata)
        }

        /// Gets the left and right channel playback volume for player.
        public func getVolume() -> (Float, Float) {
            var left: Float = 0
            var right: Float = 0
            fileplayer.getVolume.unsafelyUnwrapped(pointer, &left, &right)
            return (left, right)
        }

        // MARK: Internal

        /// Sets a function to be called when playback has completed.
        func setFinishCallback(
            callback: @convention(c) (
                _ soundSource: OpaquePointer?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            soundUserdata: UnsafeMutableRawPointer? = nil
        ) {
            fileplayer.setFinishCallback.unsafelyUnwrapped(pointer, callback, soundUserdata)
        }

        // MARK: Private

        /// `CallbackData` wraps the callback closure and is stored in a dynamically allocated block, which
        /// is passed as `userData` to `setFinishCallback` below.
        private struct CallbackData {
            var callback: (() -> Void)?
        }

        private var _callbackData: UnsafeMutablePointer<CallbackData>?

        private let pointer: OpaquePointer
    }
}
