public import CPlaydate

/// The Playdate audio engine provides sample playback from memory for short on-demand samples, file streaming for playing
/// longer files (uncompressed, MP3, and ADPCM formats), and a synthesis library for generating "computer-y" sounds.
/// Sound sources are grouped into channels, which can be panned separately, and various effects may be applied to the channels.
/// Additionally, signals can automate various parameters of the sound objects..
public enum Sound {
    // MARK: Public

    /// The fileplayer class is used for streaming audio from a file on disk. This requires less memory than keeping all of the
    /// file’s data in memory (as with the sampleplayer), but can increase overhead at run time.
    public class FilePlayer {
        // MARK: Lifecycle

        /// Creates a new FilePlayer.
        public init() {
            pointer = fileplayer.newPlayer().unsafelyUnwrapped
        }

        deinit { fileplayer.freePlayer(pointer) }

        // MARK: Public

        /// Returns true if player is playing
        public var isPlaying: Bool {
            fileplayer.isPlaying(pointer) == 1
        }

        /// Prepares player to stream the file at path. Returns `true` if the file exists, otherwise `false`.
        @discardableResult public func load(path: StaticString) -> Bool {
            fileplayer.loadIntoPlayer(pointer, path.utf8Start) == 0
        }

        /// Starts playing the file player. If repeat is greater than one, it loops the given number of times.
        /// If zero, it loops endlessly until it is stopped with ``stop()``
        /// Returns 1 on success, 0 if buffer allocation failed.
        @discardableResult public func play(repeat: Int32 = 1) -> Int32 {
            fileplayer.play(pointer, `repeat`)
        }

        /// Pauses the file player.
        public func pause() {
            fileplayer.pause(pointer)
        }

        /// Stops playing the file.
        public func stop() {
            fileplayer.stop(pointer)
        }

        /// Sets the buffer length of player to bufferLen seconds;
        public func setBufferLength(bufferLength: Float) {
            fileplayer.setBufferLength(pointer, bufferLength)
        }

        /// Returns the length, in seconds, of the file loaded into player.
        public func getLength() -> Float {
            fileplayer.getLength(pointer)
        }

        /// Returns `true` if player has underrun, `false` if not.
        public func didUnderrun() -> Bool {
            fileplayer.didUnderrun(pointer) == 1
        }

        /// Sets the start and end of the loop region for playback, in seconds.
        public func setLoopRange(start: Float, end: Float) {
            fileplayer.setLoopRange(pointer, start, end)
        }

        /// Sets the current offset in seconds.
        public func setOffset(_ offset: Float) {
            fileplayer.setOffset(pointer, offset)
        }

        /// Returns the current offset in seconds for player.
        public func getOffset() -> Float {
            fileplayer.getOffset(pointer)
        }

        /// Sets the playback rate for the player. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.
        /// Unlike sampleplayers, fileplayers can’t play in reverse (i.e., rate < 0).
        public func setRate(_ rate: Float) {
            fileplayer.setRate(pointer, rate)
        }

        /// Returns the playback rate for player.
        public func getRate() -> Float {
            fileplayer.getRate(pointer)
        }

        /// If `flag` evaluates to true, the player will restart playback (after an audible stutter) as soon as data is available.
        public func setStopOnUnderrun(flag: Bool) {
            fileplayer.setStopOnUnderrun(pointer, flag ? 1 : 0)
        }

        /// Sets the playback volume for left and right channels of player.
        public func setVolume(left: Float, right: Float) {
            fileplayer.setVolume(pointer, left, right)
        }

        /// Sets the playback volume of player.
        public func setVolume(_ volume: Float) {
            fileplayer.setVolume(pointer, volume, volume)
        }

        /// Gets the left and right channel playback volume for player.
        public func getVolume() -> (Float, Float) {
            var left: Float = 0
            var right: Float = 0
            fileplayer.getVolume(pointer, &left, &right)
            return (left, right)
        }

        // MARK: Private

        private let pointer: OpaquePointer
    }

    // MARK: Private

    private static var sound: playdate_sound { Playdate.playdateAPI.sound.pointee }

    private static var fileplayer: playdate_sound_fileplayer { sound.fileplayer.pointee }
}
