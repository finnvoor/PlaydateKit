import CPlaydate

public extension Network {
    class HTTPConnection {
        // MARK: Lifecycle

        /// Returns an HTTPConnection object for connecting to the given server, or `nil` if permission has been denied or not yet granted. If `port` is 0, the connection will use port 80 if usessl is false, otherwise 443. No connection is attempted until `get()` or `post()` are called.
        public init?(server: String, port: Int32, useSSL: Bool) {
            guard let pointer = http.newConnection.unsafelyUnwrapped(
                server,
                port,
                useSSL
            ) else {
                return nil
            }

            self.pointer = pointer

            http.setUserdata(pointer, Unmanaged.passUnretained(self).toOpaque())

            http.setHeaderReceivedCallback.unsafelyUnwrapped(pointer, Self.headerReceived)
            http.setHeadersReadCallback.unsafelyUnwrapped(pointer, Self.cHeadersReadCallback)
            http.setRequestCompleteCallback.unsafelyUnwrapped(pointer, Self.cRequestCompleteCallback)
            http.setConnectionClosedCallback.unsafelyUnwrapped(pointer, Self.cConnectionClosedCallback)
        }

        deinit {
            close()

            // Solves 2/3 leaks (9, 352). Still getting 72 byte leak (replicable in C: https://devforum.play.date/t/network-http-release-leaks/23092)
            release()
        }

        // MARK: Public

        /// Before connecting to a server, permission must be given by the user. Unlike in Lua, we don’t have a way to pause the runtime to present the modal dialog, so this function must be explicitly called before calling `HTTPConnection()`. `server` can be a parent domain of the connections opened, or `nil` to request access to any HTTP server. `purpose` is an optional string displayed in the permissions dialog to explain why the program is requesting access. After the user responds to the request, requestCallback is called with the given userdata argument. The return value is one of the following:
        public static func requestAccess(
            server: String?,
            port: Int32,
            useSSL: Bool,
            purpose: String?,
            callback: @convention(c) (
                _ allowed: Bool,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> System.AccessReply {
            return http.requestAccess.unsafelyUnwrapped(server, port, useSSL, purpose, callback, userdata);
        }

        /// Conflicts with headerRecieved and headersRead callbacks.
        public func enableResponseCallback() {
            http.setResponseCallback.unsafelyUnwrapped(pointer, Self.cResponseCallback)
        }

        /// Sets a closure to be called when the HTTP parser reads a header line from the connection
        public var headerReceivedCallback: ((_ key: String, _ value: String) -> Void)? = nil

        /// Sets a closure to be called after the connection has parsed the headers from the server response. At this point, `responseStatus` and `progress` can be used to query the status and size of the response, and `get()`/`post()` can queue another request if `setKeepAlive(true)` was called and the connection is still open.
        public var headersReadCallback: (() -> Void)? = nil

        /// Sets a closure to be called when data is available for reading.
        public var responseCallback: (() -> Void)? = nil

        /// Sets a closure to be called when all data for the request has been received (if the response contained a Content-Length header and the size is known) or the request times out.
        public var requestCompleteCallback: (() -> Void)? = nil

        /// Sets a closure to be called when the server has closed the connection.
        public var connectionClosedCallback: (() -> Void)? = nil

        /// Returns the number of bytes already read from the connection and the total bytes the server plans to send, if known.
        public var progress: (
            read: Int, total: Int
        ) {
            var read: CInt = 0, total: CInt = 0
            http.getProgress.unsafelyUnwrapped(
                pointer,
                &read,
                &total
            )
            return (Int(read), Int(total))
        }

        public var responseStatus: Int {
            Int(http.getResponseStatus.unsafelyUnwrapped(pointer))
        }

        public var bytesAvailable: Int {
            http.getBytesAvailable.unsafelyUnwrapped(pointer)
        }

        /// Adds 1 to the connection’s retain count, so that it won’t be freed when it scopes out of another context. This is used primarily so we can pass a connection created in Lua into C and not have to worry about the Lua wrapper’s lifespan.
        public func retain() {
            http.retain.unsafelyUnwrapped(pointer)
        }

        public func release() {
            http.release.unsafelyUnwrapped(pointer)
        }

        /// Sets the length of time (in milliseconds) to wait for the connection to the server to be made.
        public func setConnectTimeout(ms: Int) {
            http.setConnectTimeout.unsafelyUnwrapped(pointer, Int32(ms))
        }

        /// If `keepalive` is true, this causes the HTTP request to include a `Connection: keep-alive` header.
        public func setKeepAlive(_ keepAlive: Bool) {
            http.setKeepAlive.unsafelyUnwrapped(pointer, keepAlive)
        }

        /// Adds a `Range: bytes=<start>-<end>` header to the HTTP request.
        public func setByteRange(start: Int, end: Int) {
            http.setByteRange.unsafelyUnwrapped(pointer, Int32(start), Int32(end))
        }

        /// Opens the connection to the server if it’s not already open (e.g. from a previous request with keep-alive enabled) and sends a GET request with the given path and additional headers if specified.
        public func get(path: String, headersString: String = "") -> NetErr {
            return http.get.unsafelyUnwrapped(pointer, path, headersString, headersString.utf8.count)
        }

        /// Opens the connection to the server if it’s not already open (e.g. from a previous request with keep-alive enabled) and sends a request with the given method and path, additional headers if specified, and the provided data.
        public func query(method: String, path: String, headersString: String, body: String) -> NetErr {
            return http.query.unsafelyUnwrapped(pointer, method, path, headersString, headersString.utf8.count, body, body.utf8.count)
        }

        /// Equivalent to calling `query` with `method` equal to POST.
        public func post(path: String, headersString: String, body: String) -> NetErr {
            return http.post.unsafelyUnwrapped(pointer, path, headersString, headersString.utf8.count, body, body.utf8.count)
        }

        /// Sets the length of time, in milliseconds, the `read()` function will wait for incoming data before returning. The default value is 1000, or one second.
        public func setReadTimeout(ms: Int) {
            http.setReadTimeout.unsafelyUnwrapped(pointer, Int32(ms))
        }

        /// Sets the size of the connection’s read buffer. The default buffer size is 64 KB.
        public func setReadBufferSize(bytes: Int) {
            http.setReadBufferSize.unsafelyUnwrapped(pointer, Int32(bytes))
        }

        public func read(
            buffer: UnsafeMutableRawPointer,
            length: CUnsignedInt
        ) -> Int {
            return Int(http.read.unsafelyUnwrapped(pointer, buffer, length))
        }

        /// Closes the HTTP connection. The connection may be used again for another request.
        public func close() {
            http.close.unsafelyUnwrapped(pointer)
        }

        // MARK: Internal

        let pointer: OpaquePointer

        // MARK: Private

        /// Returns the last error on the connection, or `.ok` if none occurred.
        private var error: NetErr {
            http.getError.unsafelyUnwrapped(pointer)
        }

        private static let headerReceived: @convention(c) (
            OpaquePointer?,
            UnsafePointer<CChar>?,
            UnsafePointer<CChar>?
        ) -> Void = { cConn, cKey, cValue in
            guard
                let cConn = cConn,
                let userdata = http.getUserdata(cConn)
            else { return }
            let swiftConn = Unmanaged<HTTPConnection>.fromOpaque(userdata).takeUnretainedValue()
            let key = cKey.flatMap { String(cString: $0) } ?? ""
            let value = cValue.flatMap { String(cString: $0) } ?? ""
            swiftConn.headerReceivedCallback?(key, value)
        }

        private static let cHeadersReadCallback: @convention(c) (OpaquePointer?) -> Void = { cConn in
            guard
                let cConn = cConn,
                let userdata = http.getUserdata(cConn)
            else { return }
            let swiftConn = Unmanaged<HTTPConnection>.fromOpaque(userdata).takeUnretainedValue()
            swiftConn.headersReadCallback?()
        }

        private static let cResponseCallback: @convention(c) (OpaquePointer?) -> Void = { cConn in
            guard
                let cConn = cConn,
                let userdata = http.getUserdata(cConn)
            else { return }
            let swiftConn = Unmanaged<HTTPConnection>.fromOpaque(userdata).takeUnretainedValue()
            swiftConn.responseCallback?()
        }

        private static let cRequestCompleteCallback: @convention(c) (OpaquePointer?) -> Void = { cConn in
            guard
                let cConn = cConn,
                let userdata = http.getUserdata(cConn)
            else { return }
            let swiftConn = Unmanaged<HTTPConnection>.fromOpaque(userdata).takeUnretainedValue()
            swiftConn.requestCompleteCallback?()
        }

        private static let cConnectionClosedCallback: @convention(c) (OpaquePointer?) -> Void = { cConn in
            guard
                let cConn = cConn,
                let userdata = http.getUserdata(cConn)
            else { return }
            let swiftConn = Unmanaged<HTTPConnection>.fromOpaque(userdata).takeUnretainedValue()
            swiftConn.connectionClosedCallback?()
        }
    }
}
