import CPlaydate

/// Functions related to networking.
///
/// Playdate OS 2.7 adds support for both HTTP and TCP networking. The device supports up to four simultaneous connections.
public enum Network {
    // MARK: Public

    public typealias NetErr = PDNetErr

    /// Playdate will connect to the configured access point automatically as needed and turn off the wifi radio after a 30 second idle timeout. This function allows a game to start connecting to the access point sooner, since that can take upwards of 10 seconds, or turn off wifi as soon as it’s no longer needed instead of waiting 30 seconds. If `enabled` is true, a callback function can be provided to check for an error connecting to the access point.
    public static func setEnabled(
        _ enabled: Bool,
        callback: (@convention(c) (_ err: NetErr) -> Void)? = nil
    ) {
        network.setEnabled.unsafelyUnwrapped(enabled, callback)
    }

    public static func getStatus() -> WifiStatus {
        return network.getStatus.unsafelyUnwrapped()
    }

    // MARK: Internal
    static var network: playdate_network { Playdate.playdateAPI.network.pointee }

    static var http: playdate_http { network.http.pointee }
}
