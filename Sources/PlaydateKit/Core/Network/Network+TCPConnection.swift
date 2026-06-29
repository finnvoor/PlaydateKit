import CPlaydate

extension Network {
    public class TCPConnection {
        // MARK: Lifecycle

        /// Returns a TCPConnection object for connecting to the given server, or `nil` if permission has been denied or not yet granted. No connection is attempted until `open()` is called.
        public init?(server: String, port: Int32, useSSL: Bool) {
            guard
                let pointer = tcp.newConnection.unsafelyUnwrapped(
                    server,
                    port,
                    useSSL
                )
            else {
                return nil
            }

            self.pointer = pointer

            tcp.setUserdata(pointer, Unmanaged.passUnretained(self).toOpaque())

            tcp.setConnectionClosedCallback.unsafelyUnwrapped(
                pointer, Self.cConnectionClosedCallback)
        }

        deinit {
            _ = close()
            release()
        }

        // MARK: Public

        /// Before connecting to a server, permission must be given by the user. Unlike in Lua, we don't have a way to pause the runtime to present the modal dialog, so this function must be explicitly called before calling `TCPConnection()`. `server` can be a parent domain of the connections opened, or `nil` to request access to any server. Similarly, if `port` is zero, this requests access to all ports on the target server(s). `purpose` is an optional string displayed in the permissions dialog to explain why the program is requesting access. After the user responds to the request, requestCallback is called with the given userdata argument.
        public static func requestAccess(
            server: String?,
            port: Int32,
            useSSL: Bool,
            purpose: String?,
            callback:
                @convention(c) (
                    _ allowed: Bool,
                    _ userdata: UnsafeMutableRawPointer?
                ) -> Void,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> System.AccessReply {
            return tcp.requestAccess.unsafelyUnwrapped(
                server, port, useSSL, purpose, callback, userdata)
        }

        /// Sets a closure to be called when the connection is closed.
        public var connectionClosedCallback: ((_ error: NetErr) -> Void)? = nil

        /// Returns the number of bytes currently available for reading from the connection.
        public var bytesAvailable: Int {
            tcp.getBytesAvailable.unsafelyUnwrapped(pointer)
        }

        /// Adds 1 to the connection's retain count, so that it won't be freed when it scopes out of another context.
        public func retain() {
            _ = tcp.retain.unsafelyUnwrapped(pointer)
        }

        public func release() {
            tcp.release.unsafelyUnwrapped(pointer)
        }

        /// Sets the length of time (in milliseconds) to wait for the connection to the server to be made.
        public func setConnectTimeout(ms: Int) {
            tcp.setConnectTimeout.unsafelyUnwrapped(pointer, Int32(ms))
        }

        /// Attempts to open the connection to the server. Note that an error may be returned immediately, or in the open callback depending on where it occurs.
        public func open(
            callback:
                @convention(c) (
                    _ connection: OpaquePointer?,
                    _ error: NetErr,
                    _ userdata: UnsafeMutableRawPointer?
                ) -> Void,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> NetErr {
            return tcp.open.unsafelyUnwrapped(pointer, callback, userdata)
        }

        /// Closes the connection. The connection may be used again for another request.
        public func close() -> NetErr {
            return tcp.close.unsafelyUnwrapped(pointer)
        }

        /// Sets the length of time, in milliseconds, `read()` will wait for incoming data before returning. The default value is 1000, or one second.
        public func setReadTimeout(ms: Int) {
            tcp.setReadTimeout.unsafelyUnwrapped(pointer, Int32(ms))
        }

        /// Sets the size of the connection's read buffer. The default buffer size is 64 KB.
        public func setReadBufferSize(bytes: Int) {
            tcp.setReadBufferSize.unsafelyUnwrapped(pointer, Int32(bytes))
        }

        /// Attempts to read up to `length` bytes from the connection into `buffer`. If `length` is more than the number of bytes available on the connection the function will wait for more data, up to the length of time set by `setReadTimeout()` (default one second). If `buffer` is `nil`, the requested data is discarded. Returns the number of bytes actually read (or discarded), or a negative `PDNetErr` value on error.
        public func read(
            buffer: UnsafeMutableRawPointer?,
            length: Int
        ) -> Int {
            return Int(tcp.read.unsafelyUnwrapped(pointer, buffer, length))
        }

        /// Attempts to write up to `length` bytes to the connection. Returns the number of bytes actually written, which may be less than `length`, or a negative `PDNetErr` value on error.
        public func write(
            buffer: UnsafeRawPointer,
            length: Int
        ) -> Int {
            return Int(tcp.write.unsafelyUnwrapped(pointer, buffer, length))
        }

        // MARK: Internal

        let pointer: OpaquePointer

        // MARK: Private

        private var error: NetErr {
            tcp.getError.unsafelyUnwrapped(pointer)
        }

        private static let cConnectionClosedCallback:
            @convention(c) (OpaquePointer?, PDNetErr) -> Void = { cConn, err in
                guard
                    let cConn = cConn,
                    let userdata = tcp.getUserdata(cConn)
                else { return }
                let swiftConn = Unmanaged<TCPConnection>.fromOpaque(userdata).takeUnretainedValue()
                swiftConn.connectionClosedCallback?(err)
            }
    }
}
