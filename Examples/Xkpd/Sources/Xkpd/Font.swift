import PlaydateKit

enum Font {
    nonisolated(unsafe) static let NicoBold16: Graphics.Font = try! Graphics.Font(path: "fonts/nicoBold16")

    nonisolated(unsafe) static let NicoClean16: Graphics.Font = try! Graphics.Font(path: "fonts/nicoClean16")

    nonisolated(unsafe) static let NicoPups16: Graphics.Font = try! Graphics.Font(path: "fonts/nicoPups16")
}
