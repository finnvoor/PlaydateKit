public import CPlaydate

public enum Sound {
    public class FilePlayer {
        private let pointer: OpaquePointer

        public init() {
            pointer = fileplayer.newPlayer().unsafelyUnwrapped
        }

        /// Prepares player to stream the file at path. Returns `true` if the file exists, otherwise `false`.
        @discardableResult
        public func load(path: StaticString) -> Bool {
            fileplayer.loadIntoPlayer(pointer, path.utf8Start) == 0
        }

        /// Starts playing the file player. If repeat is greater than one, it loops the given number of times.
        /// If zero, it loops endlessly until it is stopped with `FilePlayer.stop()`
        /// Returns 1 on success, 0 if buffer allocation failed.
        @discardableResult
        public func play(repeat: Int32 = 1) -> Int32 {
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
        func setBufferLength(bufferLength: Float) {
            fileplayer.setBufferLength(pointer, bufferLength)
        }

        /// Returns the length, in seconds, of the file loaded into player.
        func getLength() -> Float {
            fileplayer.getLength(pointer)
        }

        /// Returns `true` if player has underrun, `false` if not.
        func didUnderrun() -> Bool {
            fileplayer.didUnderrun(pointer) == 1
        }

        /// Sets the start and end of the loop region for playback, in seconds.
        func setLoopRange(start: Float, end: Float) {
            fileplayer.setLoopRange(pointer, start, end)
        }

        /// Sets the current offset in seconds.
        func setOffset(_ offset: Float) {
            fileplayer.setOffset(pointer, offset)
        }

        /// Returns the current offset in seconds for player.
        func getOffset() -> Float {
            fileplayer.getOffset(pointer)
        }

        /// Sets the playback rate for the player. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.
        /// Unlike sampleplayers, fileplayers can’t play in reverse (i.e., rate < 0).
        func setRate(_ rate: Float) {
            fileplayer.setRate(pointer, rate)
        }

        /// Returns the playback rate for player.
        func getRate() -> Float {
            fileplayer.getRate(pointer)
        }

        /// If `flag` evaluates to true, the player will restart playback (after an audible stutter) as soon as data is available.
        func setStopOnUnderrun(flag: Bool) {
            fileplayer.setStopOnUnderrun(pointer, flag ? 1 : 0)
        }

        /// Sets the playback volume for left and right channels of player.
        func setVolume(left: Float, right: Float) {
            fileplayer.setVolume(pointer, left, right)
        }

        /// Sets the playback volume of player.
        func setVolume(_ volume: Float) {
            fileplayer.setVolume(pointer, volume, volume)
        }

        /// Gets the left and right channel playback volume for player.
        func getVolume() -> (Float, Float) {
            var left: Float = 0
            var right: Float = 0
            fileplayer.getVolume(pointer, &left, &right)
            return (left, right)
        }

        /// Frees the given player.
        public func free() {
            _ =  fileplayer.freePlayer(pointer)
        }

        /// Returns one if player is playing
        var isPlaying: Bool {
            fileplayer.isPlaying(pointer) == 1
        }
    }

    private static var sound: playdate_sound { Playdate.playdateAPI.sound.pointee }

    private static var fileplayer: playdate_sound_fileplayer { sound.fileplayer.pointee }
}
