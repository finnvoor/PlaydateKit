public import CPlaydate

/// Functions related to audio playback.
///
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
        /// Returns 1 on success, 0 if buffer allocation failed.
        @discardableResult public func play(repeat: Int32 = 1) -> Int32 {
            fileplayer.play.unsafelyUnwrapped(pointer, `repeat`)
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

    public class SamplePlayer {
        // MARK: Lifecycle

        /// Creates a new SamplePlayer.
        public init() {
            playerPointer = sampleplayer.newPlayer.unsafelyUnwrapped().unsafelyUnwrapped
        }

        deinit {
            if let samplePointer {
                sample.freeSample(samplePointer)
            }
            sampleplayer.freePlayer.unsafelyUnwrapped(playerPointer)
        }

        // MARK: Public

        /// Returns `true` if player is playing a sample, `false` if not.
        public var isPlaying: Bool {
            sampleplayer.isPlaying.unsafelyUnwrapped(playerPointer) == 1
        }

        /// Assigns sample to player.
        @discardableResult public func setSample(path: String) -> Bool {
            if let samplePointer {
                sample.freeSample(samplePointer)
            }

            samplePointer = sample.load(path)
            guard samplePointer != nil else { return false }

            sampleplayer.setSample(playerPointer, samplePointer)
            return true
        }

        /// Stops playing the sample.
        public func stop() {
            sampleplayer.stop.unsafelyUnwrapped(playerPointer)
        }

        /// Returns the length, in seconds, of the sample assigned to player.
        public func getLength() -> Float {
            sampleplayer.getLength.unsafelyUnwrapped(playerPointer)
        }

        /// Starts playing the sample in player.
        ///
        /// If repeat is greater than one, it loops the given number of times. If zero, it loops endlessly until it is stopped with /// playdate->sound->sampleplayer->stop(). If negative one, it does ping-pong looping.
        ///
        /// rate is the playback rate for the sample; 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an /// octave, etc.
        ///
        /// Returns `true` on success (which is always, currently).
        @discardableResult public func play(repeat: Int32 = 1, rate: Float = 1.0) -> Bool {
            sampleplayer.play.unsafelyUnwrapped(playerPointer, `repeat`, rate) == 1
        }

        /// Sets a function to be called when playback has completed.
        public func setFinishCallback(
            callback: @convention(c) (
                _ soundSource: OpaquePointer?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            soundUserdata: UnsafeMutableRawPointer? = nil
        ) {
            sampleplayer.setFinishCallback.unsafelyUnwrapped(playerPointer, callback, soundUserdata)
        }

        /// Sets the current offset of the SamplePlayer, in seconds.
        public func setOffset(_ offset: Float) {
            sampleplayer.setOffset.unsafelyUnwrapped(playerPointer, offset)
        }

        /// Returns the current offset in seconds for player.
        public func getOffset() -> Float {
            sampleplayer.getOffset.unsafelyUnwrapped(playerPointer)
        }

        /// When used with a repeat of -1, does ping-pong looping, with a start and end position in frames.
        public func setPlayRange(start: Int32, end: Int32) {
            sampleplayer.setPlayRange.unsafelyUnwrapped(playerPointer, start, end)
        }

        /// Pauses or resumes playback.
        public func setPaused(_ paused: Bool = true) {
            sampleplayer.setPaused(playerPointer, paused ? 1 : 0)
        }

        /// Sets the playback rate for the player. 1.0 is normal speed, 0.5 is down an octave, 2.0 is up an octave, etc.
        /// A negative rate produces backwards playback for PCM files, but does not work for ADPCM-encoded files.
        public func setRate(_ rate: Float) {
            sampleplayer.setRate.unsafelyUnwrapped(playerPointer, rate)
        }

        /// Returns the playback rate for player.
        public func getRate() -> Float {
            sampleplayer.getRate.unsafelyUnwrapped(playerPointer)
        }

        /// Sets the playback volume for left and right channels.
        public func setVolume(left: Float, right: Float) {
            sampleplayer.setVolume.unsafelyUnwrapped(playerPointer, left, right)
        }

        /// Sets the playback volume for both left and right.
        public func setVolume(_ volume: Float) {
            sampleplayer.setVolume.unsafelyUnwrapped(playerPointer, volume, volume)
        }

        /// Gets the current left and right channel volume of the sampleplayer.
        public func getVolume() -> (Float, Float) {
            var left: Float = 0
            var right: Float = 0
            sampleplayer.getVolume.unsafelyUnwrapped(playerPointer, &left, &right)
            return (left, right)
        }

        // MARK: Private

        private let playerPointer: OpaquePointer
        private var samplePointer: OpaquePointer?
    }

    public class Synth {
        // MARK: Lifecycle

        /// Creates a new synth object to play a waveform or wavetable. See ``Sound/Synth/setWaveform(_:)`` for waveform values.
        public init() {
            pointer = synth.newSynth.unsafelyUnwrapped().unsafelyUnwrapped
        }

        deinit {
            synth.freeSynth.unsafelyUnwrapped(pointer)
        }

        // MARK: Public

        public func setWaveform(_ waveform: SoundWaveform) {
            synth.setWaveform.unsafelyUnwrapped(pointer, waveform)
        }

        /// Sets the attack time, in seconds.
        public func setAttackTime(_ attackTime: Float) {
            synth.setAttackTime.unsafelyUnwrapped(pointer, attackTime)
        }

        /// Sets the decay time, in seconds.
        public func setDecayTime(_ decayTime: Float) {
            synth.setDecayTime.unsafelyUnwrapped(pointer, decayTime)
        }

        /// Sets the sustain level, as a proportion of the total level (0.0 to 1.0).
        public func setSustainLevel(_ sustainLevel: Float) {
            synth.setSustainLevel.unsafelyUnwrapped(pointer, sustainLevel)
        }

        /// Sets the release time, in seconds.
        public func setReleaseTime(_ releaseTime: Float) {
            synth.setReleaseTime.unsafelyUnwrapped(pointer, releaseTime)
        }

        /// Plays a note with the current waveform or sample.
        /// - Parameters:
        ///   - frequency: The frequency of the note to play.
        ///   - volume: 0 to 1, defaults to 1
        ///   - length: In seconds. If omitted, note will play until you call noteOff()
        ///   - when: Seconds since the sound engine started (see ``Sound/currentTime``). Defaults to the current time.
        public func playNote(frequency: Float, volume: Float = 1, length: Float = -1, when: CUnsignedInt = 0) {
            synth.playNote.unsafelyUnwrapped(pointer, frequency, volume, length, when)
        }

        /// Sends a note off event to the synth.
        /// - Parameter when: The scheduled time to send a note off event. Defaults to immediately.
        public func noteOff(when: CUnsignedInt = 0) {
            synth.noteOff.unsafelyUnwrapped(pointer, when)
        }

        // MARK: Private

        private let pointer: OpaquePointer
    }

    /// Returns the current time, in seconds, as measured by the audio device.
    /// The audio device uses its own time base in order to provide accurate timing.
    public static var currentTime: CUnsignedInt {
        sound.getCurrentTime.unsafelyUnwrapped()
    }

    // MARK: Private

    private static var sound: playdate_sound { Playdate.playdateAPI.sound.pointee }
    private static var sample: playdate_sound_sample { sound.sample.pointee }
    private static var synth: playdate_sound_synth { sound.synth.pointee }

    private static var fileplayer: playdate_sound_fileplayer { sound.fileplayer.pointee }
    private static var sampleplayer: playdate_sound_sampleplayer { sound.sampleplayer.pointee }
}
