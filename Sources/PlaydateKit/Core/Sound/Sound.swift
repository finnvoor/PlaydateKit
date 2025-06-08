import CPlaydate

/// Functions related to audio playback.
///
/// The Playdate audio engine provides sample playback from memory for short on-demand samples, file streaming for playing
/// longer files (uncompressed, MP3, and ADPCM formats), and a synthesis library for generating "computer-y" sounds.
/// Sound sources are grouped into channels, which can be panned separately, and various effects may be applied to the channels.
/// Additionally, signals can automate various parameters of the sound objects..
public enum Sound {
    // MARK: Public

    /// Returns the current time, in seconds, as measured by the audio device.
    /// The audio device uses its own time base in order to provide accurate timing.
    public static var currentTime: CUnsignedInt {
        sound.getCurrentTime.unsafelyUnwrapped()
    }

    public static var defaultChannel: Channel {
        Channel(pointer: sound.getDefaultChannel().unsafelyUnwrapped, free: false)
    }

    public static var headphoneState: (headphone: Bool, mic: Bool) {
        var headphone: CInt = 0
        var mic: CInt = 0
        sound.getHeadphoneState.unsafelyUnwrapped(&headphone, &mic, nil)
        return (headphone != 0, mic != 0)
    }

    public static func addChannel(_ channel: Channel) -> Bool {
        sound.addChannel.unsafelyUnwrapped(channel.pointer) == 1
    }

    public static func removeSource(_ source: Source) -> Bool {
        sound.removeSource.unsafelyUnwrapped(source.pointer) == 1
    }

    public static func removeChannel(_ channel: Channel) -> Bool {
        sound.removeChannel.unsafelyUnwrapped(channel.pointer) == 1
    }

    public static func setOutputsActive(headphone: Bool, speaker: Bool) {
        sound.setOutputsActive.unsafelyUnwrapped(headphone ? 1 : 0, speaker ? 1 : 0)
    }

    // MARK: Internal

    static var sound: playdate_sound { Playdate.playdateAPI.sound.pointee }

    static var channel: playdate_sound_channel { sound.channel.pointee }
    static var source: playdate_sound_source { sound.source.pointee }
    static var sample: playdate_sound_sample { sound.sample.pointee }
    static var fileplayer: playdate_sound_fileplayer { sound.fileplayer.pointee }
    static var sampleplayer: playdate_sound_sampleplayer { sound.sampleplayer.pointee }
    static var synth: playdate_sound_synth { sound.synth.pointee }
    static var instrument: playdate_sound_instrument { sound.instrument.pointee }
    static var signal: playdate_sound_signal { sound.signal.pointee }
    static var envelope: playdate_sound_envelope { sound.envelope.pointee }
    static var sequence: playdate_sound_sequence { sound.sequence.pointee }
    static var track: playdate_sound_track { sound.track.pointee }
}
