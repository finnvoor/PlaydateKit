import PlaydateKit
import UTF8ViewExtensions

import CLodePNG
import CQRCode

class Comic {
    // MARK: Lifecycle

    /// Initialize the latest comic
    init(metadataUrl: String = "https://xkcd.com/info.0.json") {
        self.metadataUrl = metadataUrl
        isLatest = true

        loadMetadata()
    }

    /// Initialize a specific comic
    init(num: Int) {
        self.num = num
        metadataUrl = "https://xkcd.com/\(num)/info.0.json"
        isLatest = false

        loadMetadata()
    }

    // MARK: Internal

    enum State {
        case loadingMetadataHeaders
        case loadingMetadata
        case loadingImageHeaders
        case loadingImage
        case loaded
        case error(message: String)
    }

    var state = State.loadingMetadataHeaders {
        didSet {
            switch state {
            case .loaded:
                SFX.instance.play(.comicLoaded)
            case .error:
                SFX.instance.play(.error)
            default:
                break
            }
        }
    }

    var connection: Network.HTTPConnection?

    let metadataUrl: String

    let isLatest: Bool

    var num: Int = 0
    // Always empty string?
    var link: String = ""

    var year: String = ""
    var month: String = ""
    var day: String = ""

    var title: String = ""
    // `safe_title` in JSON. Some sort of sanitization (HTML?), see https://xkcd.com/3028/info.0.json
    var safeTitle: String = ""
    var alt: String = ""
    var transcript: String = ""
    // Contains encoded HTML, see https://xkcd.com/3074/info.0.json
    var news: String = ""

    var imgUrl: String = "" // `img` in JSON

    var sprite: Sprite.Sprite?

    var imgWidth: Int = 0

    var imgHeight: Int = 0

    var qrBitmap: Graphics.Bitmap?

    // MARK: Private

    private var metadataLoadStart = System.elapsedTime

    private var imgLoadStart = System.elapsedTime

    private func loadMetadata() {
        print("Loading metadata from \(metadataUrl)")

        metadataLoadStart = System.elapsedTime

        guard let conn = makeConnection(server: "xkcd.com") else {
            return
        }

        conn.requestCompleteCallback = self.handleGetMetadataComplete
        let err = conn.get(path: metadataUrl)

        if err != .ok {
            state = .error(message: "Error loading metadata: \(err.rawValue)")
            return
        }

        connection = conn
    }

    private func loadImage() {
        print("Loading image from \(imgUrl)")
        state = .loadingImageHeaders
        imgLoadStart = System.elapsedTime

        guard let conn = makeConnection(server: "imgs.xkcd.com") else {
            return
        }

        conn.setReadBufferSize(bytes: 2_000_000)
        conn.requestCompleteCallback = self.handleGetImageComplete
        let err = conn.get(path: imgUrl)

        if err != .ok {
            state = .error(message: "Error loading image: \(err.rawValue)")
            return
        }

        connection = conn
    }

    private func makeConnection(server: String) -> Network.HTTPConnection? {
        guard let conn = Network.HTTPConnection(server: server, port: 443, useSSL: true) else {
            state = .error(message: "Couldn't create HTTP connection to \(server)")
            return nil
        }

        conn.headerReceivedCallback = self.handleHeaderReceived
        conn.headersReadCallback = self.handleHeadersRead
        conn.connectionClosedCallback = self.handleConnectionClosed

        return conn
    }

    private func handleHeaderReceived(key: String, value: String) {
//        print("Got header \(key): \(value)")
    }

    private func handleHeadersRead() {
        switch state {
        case .loadingMetadataHeaders:
            state = .loadingMetadata
        case .loadingImageHeaders:
            state = .loadingImage
        default:
            break
        }
    }

    private func handleGetMetadataComplete() {
        guard let connection = connection else {
            return
        }

        let bytesAvailable = connection.bytesAvailable

        print("Got metadata in \(Int((System.elapsedTime - metadataLoadStart) * 1000)) ms (Status \(connection.responseStatus), \(bytesAvailable) bytes)")

        if connection.responseStatus != 200 {
            state = .error(message: "Unexpected response \(connection.responseStatus)")
            return
        }

        let buf = UnsafeMutableRawPointer.allocate(byteCount: bytesAvailable, alignment: 1)

        let bytesRead = connection.read(buffer: buf, length: CUnsignedInt(bytesAvailable))

        let uint8Buffer = UnsafeBufferPointer<UInt8>(start: buf.assumingMemoryBound(to: UInt8.self), count: bytesRead)
        let jsonString = String(decoding: uint8Buffer, as: Unicode.UTF8.self)

        buf.deallocate()

        print(jsonString)

        var decoder = JSON.Decoder()
        decoder.userdata = Unmanaged.passUnretained(self).toOpaque()
        decoder.decodeError = Self.decodeError
        decoder.didDecodeTableValue = Self.didDecodeTableValue

        var value = JSON.Value()
        let jsonSuccess = JSON.decodeString(using: &decoder, jsonString: jsonString, value: &value)

        self.connection = nil

        if jsonSuccess != 1 {
            return
        }

        if !imgUrl.utf8.hasSuffix(".png") {
            let ext: String.UTF8View.SubSequence
            if let lastDotIndex = imgUrl.utf8.lastIndex(of: UInt8(ascii: ".")) {
                ext = imgUrl.utf8.suffix(from: lastDotIndex)
            } else {
                ext = "unknown".utf8.suffix(from: "".utf8.startIndex)
            }
            state = .error(message: "Unsupported image format \(String(decoding: ext, as: UTF8.self))")
            return
        }

        // https://github.com/ricmoo/QRCode

        var qrCode = QRCode()
        let bufSize = qrcode_getBufferSize(2)
        let qrData = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufSize))
        defer { qrData.deallocate() }

        let qrGenerateStart = System.elapsedTime

        qrcode_initText(&qrCode, qrData, 2, UInt8(ECC_QUARTILE), "HTTPS://XKCD.COM/\(num)")

        print("Generated QR in \(Int((System.elapsedTime - qrGenerateStart) * 1000)) ms")

        qrBitmap = Graphics.Bitmap(width: 25, height: 25, bgColor: .black)

        Graphics.pushContext(qrBitmap)
        for y in 0..<25 {
            for x in 0..<25 {
                let module = qrcode_getModule(&qrCode, UInt8(x), UInt8(y))

                if module != 0 {
                    Graphics.setPixel(at: Point(x: x, y: y), to: .white)
                }
            }
        }
        Graphics.popContext()

        self.qrBitmap = qrBitmap?.rotated(by: 0, xScale: 3, yScale: 3).bitmap

        loadImage()
    }

    private func handleGetImageComplete() {
        guard let connection = connection else {
            return
        }

        let bytesAvailable = connection.bytesAvailable

        print("Got image in \(Int((System.elapsedTime - imgLoadStart) * 1000)) ms (Status \(connection.responseStatus), \(bytesAvailable) bytes)")

        let buf = UnsafeMutableRawPointer.allocate(byteCount: bytesAvailable, alignment: 1)
        defer { buf.deallocate() }

        let bytesRead = connection.read(buffer: buf, length: CUnsignedInt(bytesAvailable))

        self.connection = nil

        // FIXME: This happens occasionally on sim (because 0 bytes were available). I haven't been able to replicate on device.
        if bytesRead < bytesAvailable {
            state = .error(message: "Couldn't load image (read \(bytesRead) bytes instead of \(bytesAvailable))")
            return
        }

        let uint8Buffer = UnsafeBufferPointer<UInt8>(start: buf.assumingMemoryBound(to: UInt8.self), count: bytesRead)

        var width: Int32 = 0
        var height: Int32 = 0

        var imageData: UnsafeMutablePointer<UInt8>? = nil
        defer {
            if let data = imageData {
                free(data)
            }
        }

        let decodeStartTime = System.elapsedTime

        lodepng_decode24(&imageData, &width, &height, uint8Buffer.baseAddress!, bytesRead)

        print("Decoded image in \(Int((System.elapsedTime - decodeStartTime) * 1000)) ms")

        print("Decoded image dimensions \(width)x\(height)")

        imgWidth = Int(width)
        imgHeight = Int(height)

        let bitmapStartTime = System.elapsedTime

        let bitmap = Graphics.Bitmap(width: imgWidth, height: imgHeight, bgColor: .black)

        Graphics.pushContext(bitmap)

        for y in 0..<imgHeight {
            for x in 0..<imgWidth {
                let pixelIndex = (y * imgWidth + x) * 3
                let r = imageData![pixelIndex]
                let g = imageData![pixelIndex + 1]
                let b = imageData![pixelIndex + 2]
                let l = 0.2126 * Float(r) + 0.7152 * Float(g) + 0.0722 * Float(b)

                let l2 = l / 255

                Graphics.setPixel(
                    at: Point(x: x, y: y),
                    to: Graphics.Color.sampleBayer4x4(x: x, y: y, b: l2 * l2)
                )
            }
        }

        print("Drew bitmap in \(Int((System.elapsedTime - bitmapStartTime) * 1000)) ms")

        Graphics.popContext()

        let sprite = Sprite.Sprite()
        sprite.image = bitmap
        sprite.center = Point.zero
        sprite.moveTo(Point.zero)
        sprite.addToDisplayList()
        self.sprite = sprite

        state = .loaded
    }

    private func handleConnectionClosed() {
        print("Connection closed")
    }

    private static nonisolated(unsafe) var decodeError: @convention(c)
    (UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, Int32) -> Void
    = { ptr, err, line in
        guard
            let ptr = ptr,
            let ctxPtr = ptr.pointee.userdata
        else { return }

        let comic = Unmanaged<Comic>
            .fromOpaque(ctxPtr)
            .takeUnretainedValue()

        if let e = err.map({ String(cString: $0) }) {
            comic.state = .error(message: "JSON error at \(line): \(e)")
        }
    }

    static nonisolated(unsafe) var didDecodeTableValue: @convention(c)
    (UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, json_value) -> Void
    = { ptr, keyC, val in
        guard
            let ptr = ptr,
            let keyC = keyC,
            let ctxPtr = ptr.pointee.userdata
        else { return }

        let key = String(cString: keyC).utf8

        let comic = Unmanaged<Comic>
            .fromOpaque(ctxPtr)
            .takeUnretainedValue()

        let type = json_value_type(rawValue: numericCast(val.type))

        switch key {
        case "num":
            comic.num = Int(val.data.intval)
        case "link":
            comic.link = String(cString: val.data.stringval)
        case "year":
            comic.year = String(cString: val.data.stringval)
        case "month":
            comic.month = String(cString: val.data.stringval)
        case "day":
            comic.day = String(cString: val.data.stringval)
        case "title":
            comic.title = String(cString: val.data.stringval)
        case "safe_title":
            comic.safeTitle = String(cString: val.data.stringval)
        case "alt":
            comic.alt = String(cString: val.data.stringval)
        case "transcript":
            comic.transcript = String(cString: val.data.stringval)
        case "news":
            comic.news = String(cString: val.data.stringval)
        case "img":
            comic.imgUrl = String(cString: val.data.stringval)
        default:
            print("Skipping unknown key \(key)")
            break
        }
    }
}
