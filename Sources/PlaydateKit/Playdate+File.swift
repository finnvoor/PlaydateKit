@preconcurrency public import CPlaydate

public extension Playdate {
    enum File {
        // MARK: Public

        /// Returns human-readable text describing the most recent error
        /// (usually indicated by a -1 return from a filesystem function).
        public static var lastError: Error {
            Error(humanReadableText: file.geterr())
        }

        /// Calls the given callback function for every file at path. Subfolders are indicated by a trailing slash '/' in filename.
        /// `listFiles()` does not recurse into subfolders. If showHidden is true, files beginning with a period will be included;
        /// otherwise, they are skipped. Throws if no folder exists at path or it can’t be opened.
        public static func listFiles(
            path: StaticString,
            callback: @convention(c) (
                _ filename: UnsafePointer<CChar>?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            userdata: UnsafeMutableRawPointer?,
            showHidden: Bool
        ) throws(Error) {
            guard file.listfiles(path.utf8Start, callback, userdata, showHidden ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Calls the given callback function for every file at path. Subfolders are indicated by a trailing slash '/' in filename.
        /// `listFiles()` does not recurse into subfolders. If showHidden is true, files beginning with a period will be included;
        /// otherwise, they are skipped. Throws if no folder exists at path or it can’t be opened.
        public static func listFiles(
            path: UnsafePointer<CChar>,
            callback: @convention(c) (
                _ filename: UnsafePointer<CChar>?,
                _ userdata: UnsafeMutableRawPointer?
            ) -> Void,
            userdata: UnsafeMutableRawPointer?,
            showHidden: Bool
        ) throws(Error) {
            guard file.listfiles(path, callback, userdata, showHidden ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Deletes the file at path. If recursive is true and the target path is a folder,
        /// this deletes everything inside the folder (including folders, folders inside those, and so on) as well as the folder itself.
        public static func unlink(path: StaticString, recursive: Bool) throws(Error) {
            guard file.unlink(path.utf8Start, recursive ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Deletes the file at path. If recursive is true and the target path is a folder,
        /// this deletes everything inside the folder (including folders, folders inside those, and so on) as well as the folder itself.
        public static func unlink(path: UnsafePointer<CChar>, recursive: Bool) throws(Error) {
            guard file.unlink(path, recursive ? 1 : 0) == 0 else {
                throw lastError
            }
        }

        /// Creates the given path in the `Data/<gameid>` folder. It does not create intermediate folders.
        public static func mkdir(path: StaticString) throws(Error) {
            guard file.mkdir(path.utf8Start) == 0 else {
                throw lastError
            }
        }

        /// Creates the given path in the `Data/<gameid>` folder. It does not create intermediate folders.
        public static func mkdir(path: UnsafePointer<CChar>) throws(Error) {
            guard file.mkdir(path) == 0 else {
                throw lastError
            }
        }

        /// Renames the file at from to to. It will overwrite the file at to without confirmation.
        /// It does not create intermediate folders.
        public static func rename(from: StaticString, to: StaticString) throws(Error) {
            guard file.rename(from.utf8Start, to.utf8Start) == 0 else {
                throw lastError
            }
        }

        /// Renames the file at from to to. It will overwrite the file at to without confirmation.
        /// It does not create intermediate folders.
        public static func rename(from: UnsafePointer<CChar>, to: UnsafePointer<CChar>) throws(Error) {
            guard file.rename(from, to) == 0 else {
                throw lastError
            }
        }

        /// Returns the FileStat stat with information about the file at path.
        public static func stat(path: StaticString) throws(Error) -> FileStat {
            var fileStat = FileStat()
            guard file.stat(path.utf8Start, &fileStat) == 0 else {
                throw lastError
            }
            return fileStat
        }

        /// Returns the FileStat stat with information about the file at path.
        public static func stat(path: UnsafePointer<CChar>) throws(Error) -> FileStat {
            var fileStat = FileStat()
            guard file.stat(path, &fileStat) == 0 else {
                throw lastError
            }
            return fileStat
        }

        /// Opens a handle for the file at path. The `fileRead` mode opens a file in the game pdx,
        /// while `fileReadData` searches the game’s data folder; to search the data folder first then fall back on the game pdx,
        /// use the bitwise combination `fileRead|fileReadData.fileWrite` and `fileAppend` always write to the data folder.
        /// The function returns `nil` if a file at path cannot be opened, and `lastError` will describe the error.
        /// The filesystem has a limit of 64 simultaneous open files. The returned file handle should be closed,
        /// not freed, when it is no longer in use.
        public static func open(path: StaticString, mode: FileOptions) -> UnsafeMutableRawPointer? {
            file.open(path.utf8Start, mode)
        }

        /// Opens a handle for the file at path. The `fileRead` mode opens a file in the game pdx,
        /// while `fileReadData` searches the game’s data folder; to search the data folder first then fall back on the game pdx,
        /// use the bitwise combination `fileRead|fileReadData.fileWrite` and `fileAppend` always write to the data folder.
        /// The function returns `nil` if a file at path cannot be opened, and `lastError` will describe the error.
        /// The filesystem has a limit of 64 simultaneous open files. The returned file handle should be closed,
        /// not freed, when it is no longer in use.
        public static func open(path: UnsafePointer<CChar>, mode: FileOptions) -> UnsafeMutableRawPointer? {
            file.open(path, mode)
        }

        /// Closes the given file handle.
        public static func close(file: UnsafeMutableRawPointer) throws(Error) {
            guard File.file.close(file) == 0 else {
                throw lastError
            }
        }

        /// Flushes the output buffer of file immediately. Returns the number of bytes written.
        public static func flush(file: UnsafeMutableRawPointer) throws(Error) -> Int32 {
            let writtenCount = File.file.flush(file)
            guard writtenCount != -1 else {
                throw lastError
            }
            return writtenCount
        }

        /// Reads up to len bytes from the file into the buffer buf. Returns the number of bytes read (0 indicating end of file)
        public static func read(
            file: UnsafeMutableRawPointer,
            buf: UnsafeMutableRawPointer,
            len: UInt32
        ) throws(Error) -> Int32 {
            let readCount = File.file.read(file, buf, len)
            guard readCount != -1 else {
                throw lastError
            }
            return readCount
        }

        /// Sets the read/write offset in the given file handle to pos, relative to the whence macro.
        /// SEEK_SET is relative to the beginning of the file, SEEK_CUR is relative to the current position of the file pointer,
        /// and SEEK_END is relative to the end of the file.
        public static func seek(
            file: UnsafeMutableRawPointer,
            pos: Int32,
            whence: Int32
        ) throws(Error) {
            guard File.file.seek(file, pos, whence) == 0 else {
                throw lastError
            }
        }

        /// Returns the current read/write offset in the given file handle
        public static func tell(file: UnsafeMutableRawPointer) throws(Error) -> Int32 {
            let offset = File.file.tell(file)
            guard offset != 0 else {
                throw lastError
            }
            return offset
        }

        /// Writes the buffer of bytes buf to the file. Returns the number of bytes written
        public static func write(
            file: UnsafeMutableRawPointer,
            buf: UnsafeRawPointer,
            len: UInt32
        ) throws(Error) -> Int32 {
            let writtenCount = File.file.write(file, buf, len)
            guard writtenCount != 1 else {
                throw lastError
            }
            return writtenCount
        }

        // MARK: Private

        private static var file: playdate_file { playdateAPI.file.pointee }
    }
}
