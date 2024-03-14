public import CPlaydate

public extension Playdate {
    enum JSON {
        // MARK: Public

        /// Decodes a JSON file with the given `decoder`. An instance of `json_decoder` must implement decodeError.
        /// The remaining functions are optional although you’ll probably want to implement at least didDecodeTableValue
        /// and didDecodeArrayValue. The value pointer, if set, contains the value retured from the top-level didDecodeSublist callback.
        public static func decode(
            using decoder: inout json_decoder,
            reader: json_reader,
            value: inout json_value
        ) -> Int32 {
            json.decode(&decoder, reader, &value)
        }

        /// Decodes a JSON string with the given `decoder`. An instance of `json_decoder` must implement decodeError.
        /// The remaining functions are optional although you’ll probably want to implement at least didDecodeTableValue
        /// and didDecodeArrayValue. The value pointer, if set, contains the value retured from the top-level didDecodeSublist callback.
        public static func decodeString(
            using decoder: inout json_decoder,
            jsonString: StaticString,
            value: inout json_value
        ) -> Int32 {
            json.decodeString(&decoder, jsonString.utf8Start, &value)
        }

        /// Decodes a JSON string with the given `decoder`. An instance of `json_decoder` must implement decodeError.
        /// The remaining functions are optional although you’ll probably want to implement at least didDecodeTableValue
        /// and didDecodeArrayValue. The value pointer, if set, contains the value retured from the top-level didDecodeSublist callback.
        public static func decodeString(
            using decoder: inout json_decoder,
            jsonString: UnsafeMutablePointer<CChar>,
            value: inout json_value
        ) -> Int32 {
            json.decodeString(&decoder, jsonString, &value)
        }

        /// Populates the given `json_encoder` `encoder` with the functions necessary to encode arbitrary data into a JSON string.
        /// `userdata` is passed as the first argument of the given `writeFunc` write. When pretty is true the string is written
        /// with human-readable formatting.
        public static func initEncoder(
            encoder: inout json_encoder,
            writeFunc: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<CChar>?, Int32) -> Void)?,
            userdata: UnsafeMutableRawPointer?,
            pretty: Bool
        ) {
            json.initEncoder(&encoder, writeFunc, userdata, pretty ? 1 : 0)
        }

        // MARK: Private

        private static var json: playdate_json { playdateAPI.json.pointee }
    }
}
