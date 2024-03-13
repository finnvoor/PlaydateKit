@preconcurrency public import CPlaydate

public extension Playdate {
    enum System {
        private static var system: playdate_sys { playdate.pointee.system.pointee }
        
        public static func addMenuItem(
            title: StaticString,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userData: UnsafeMutableRawPointer?
        ) {
            system.addMenuItem(title.utf8Start, callback, userData)
        }
        
        public static func logToConsole(format: StaticString) {
            typealias test = @convention(c) (UnsafePointer<CChar>?) -> Void
            let logToConsole = unsafeBitCast(system.logToConsole.unsafelyUnwrapped, to: test.self)
            format.utf8Start.withMemoryRebound(
                to: CChar.self,
                capacity: format.utf8CodeUnitCount
            ) { pointer in
                logToConsole(pointer)
            }
        }
    }
}
