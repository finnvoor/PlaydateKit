// TODO: - Temporary workaround until FloatingPoint print support is added to Embedded Swift
import CPlaydate

// MARK: - Float + CustomStringConvertible

extension Float: @retroactive CustomStringConvertible {
    public var description: String {
        var outString: UnsafeMutablePointer<CChar>?
        formatStringFloat(Playdate.playdateAPI, &outString, self)
        defer { outString?.deallocate() }
        return String(cString: outString!)
    }
}

// MARK: - Double + CustomStringConvertible

extension Double: @retroactive CustomStringConvertible {
    public var description: String {
        var outString: UnsafeMutablePointer<CChar>?
        formatStringDouble(Playdate.playdateAPI, &outString, self)
        defer { outString?.deallocate() }
        return String(cString: outString!)
    }
}
