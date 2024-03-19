public import CPlaydate

public extension Playdate {
    enum File {
        // MARK: Public

        public typealias Options = FileOptions

        public struct FileHandle {
            // MARK: Public

            public enum Seek: CInt {
                /// relative to the beginning of the file
                case beginning = 0 // SEEK_SET
                /// relative to the current position of the file pointer
                case current = 1 // SEEK_CUR
                /// relative to the end of the file
                case end = 2 // SEEK_END
            }

            /// Closes the file handle.
            public func close() throws(Error) {
                guard file.close(pointer) == 0 else { throw lastError }
            }

            /// Flushes the output buffer of file immediately. Returns the number of bytes written.
            public func flush() throws(Error) -> CInt {
                let writtenCount = file.flush(pointer)
                guard writtenCount != -1 else { throw lastError }
                return writtenCount
            }

            /// Reads up to `length` bytes from the file handle into the buffer `buffer`. Returns the number of bytes read (0 indicating end of file)
            public func read(
                buffer: UnsafeMutableRawPointer,
                length: CUnsignedInt
            ) throws(Error) -> CInt {
                let readCount = file.read(pointer, buffer, length)
                guard readCount != -1 else { throw lastError }
                return readCount
            }

            /// Sets the read/write offset in the file handle to `position`, relative to the `seek`.
            public func seek(
                to position: CInt,
                seek: Seek = .current
            ) throws(Error) {
                guard file.seek(pointer, position, seek.rawValue) == 0 else { throw lastError }
            }

            /// Returns the current read/write offset in the given file handle
            public func currentSeekPosition() throws(Error) -> CInt {
                let offset = file.tell(pointer)
                guard offset != 0 else { throw lastError }
                return offset
            }

            /// Writes the buffer of bytes `buffer` to the file. Returns the number of bytes written
            public func write(
                buffer: UnsafeRawBufferPointer
            ) throws(Error) -> CInt {
                let writtenCount = file.write(pointer, buffer.baseAddress, CUnsignedInt(buffer.count))
                guard writtenCount != 1 else { throw lastError }
                return writtenCount
            }

            // MARK: Internal

            let pointer: UnsafeMutableRawPointer
        }

        /// Calls the given callback function for every file at path. Subfolders are indicated by a trailing slash '/' in filename.
        /// `listFiles()` does not recurse into subfolders. If `showHidden` is true, files beginning with a period will be included;
        /// otherwise, they are skipped. Throws if no folder exists at path or it can’t be opened.
        public static func listFiles(
            path: StaticString,
            callback: @convention(c) (
                _ filename: UnsafePointer<CChar>?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            userdata: UnsafeMutableRawPointer? = nil,
            showHidden: Bool = false
        ) throws(Error) {
            guard file.listfiles(path.utf8Start, callback, userdata, showHidden ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Calls the given callback function for every file at path. Subfolders are indicated by a trailing slash '/' in filename.
        /// `listFiles()` does not recurse into subfolders. If `showHidden` is true, files beginning with a period will be included;
        /// otherwise, they are skipped. Throws if no folder exists at path or it can’t be opened.
        public static func listFiles(
            path: UnsafePointer<CChar>,
            callback: @convention(c) (
                _ filename: UnsafePointer<CChar>?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            userdata: UnsafeMutableRawPointer? = nil,
            showHidden: Bool = false
        ) throws(Error) {
            guard file.listfiles(path, callback, userdata, showHidden ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Deletes the file at path. If recursive is true and the target path is a folder,
        /// this deletes everything inside the folder (including folders, folders inside those, and so on) as well as the folder itself.
        public static func unlink(path: StaticString, recursive: Bool = false) throws(Error) {
            guard file.unlink(path.utf8Start, recursive ? 1 : 0) == 0 else { throw lastError }
        }

        /// Deletes the file at path. If `recursive` is true and the target path is a folder,
        /// this deletes everything inside the folder (including folders, folders inside those, and so on) as well as the folder itself.
        public static func unlink(path: UnsafePointer<CChar>, recursive: Bool = false) throws(Error) {
            guard file.unlink(path, recursive ? 1 : 0) == 0 else { throw lastError }
        }

        /// Creates the given path in the `Data/<gameid>` folder. It does not create intermediate folders.
        public static func mkdir(path: StaticString) throws(Error) {
            guard file.mkdir(path.utf8Start) == 0 else { throw lastError }
        }

        /// Creates the given path in the `Data/<gameid>` folder. It does not create intermediate folders.
        public static func mkdir(path: UnsafePointer<CChar>) throws(Error) {
            guard file.mkdir(path) == 0 else { throw lastError }
        }

        /// Renames the file at `from` to `to`. It will overwrite the file at to without confirmation.
        /// It does not create intermediate folders.
        public static func rename(from: StaticString, to: StaticString) throws(Error) {
            guard file.rename(from.utf8Start, to.utf8Start) == 0 else { throw lastError }
        }

        /// Renames the file at `from` to `to`. It will overwrite the file at to without confirmation.
        /// It does not create intermediate folders.
        public static func rename(from: UnsafePointer<CChar>, to: UnsafePointer<CChar>) throws(Error) {
            guard file.rename(from, to) == 0 else { throw lastError }
        }

        /// Returns the FileStat stat with information about the file at `path`.
        public static func stat(path: StaticString) throws(Error) -> FileStat {
            var fileStat = FileStat()
            guard file.stat(path.utf8Start, &fileStat) == 0 else { throw lastError }
            return fileStat
        }

        /// Returns the FileStat stat with information about the file at `path`.
        public static func stat(path: UnsafePointer<CChar>) throws(Error) -> FileStat {
            var fileStat = FileStat()
            guard file.stat(path, &fileStat) == 0 else { throw lastError }
            return fileStat
        }

        /// Opens a handle for the file at path. The `fileRead` mode opens a file in the game pdx,
        /// while `fileReadData` searches the game’s data folder; to search the data folder first then fall back on the game pdx,
        /// use the bitwise combination `fileRead|fileReadData.fileWrite` and `fileAppend` always write to the data folder.
        /// The function throws an error if a file at path cannot be opened.
        /// > Warning: The filesystem has a limit of 64 simultaneous open files. The returned file handle should be closed,
        /// when it is no longer in use (before deinit).
        public static func open(path: StaticString, mode: Options) throws(Error) -> FileHandle {
            guard let fileHandle = file.open(path.utf8Start, mode) else {
                throw lastError
            }
            return FileHandle(pointer: fileHandle)
        }

        /// Opens a handle for the file at path. The `fileRead` mode opens a file in the game pdx,
        /// while `fileReadData` searches the game’s data folder; to search the data folder first then fall back on the game pdx,
        /// use the bitwise combination `fileRead|fileReadData.fileWrite` and `fileAppend` always write to the data folder.
        /// The function throws an error if a file at path cannot be opened.
        /// > Warning: The filesystem has a limit of 64 simultaneous open files. The returned file handle should be closed,
        /// when it is no longer in use (before deinit).
        public static func open(path: UnsafePointer<CChar>, mode: Options) throws(Error) -> FileHandle {
            guard let fileHandle = file.open(path, mode) else {
                throw lastError
            }
            return FileHandle(pointer: fileHandle)
        }

        // MARK: Private

        /// Returns human-readable text describing the most recent error
        /// (usually indicated by a thrown error from a filesystem function).
        private static var lastError: Error {
            Error(humanReadableText: file.geterr())
        }

        private static var file: playdate_file { playdateAPI.file.pointee }
    }
}
