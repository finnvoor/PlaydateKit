import PlaydateKit

extension Graphics.Color {
    static let bayer2x2Matrix: [UInt8] = [
        0, 2,
        3, 1
    ]

    static let bayer4x4Matrix: [UInt8] = [
        0,  8, 2, 10,
        12, 4, 14, 6,
        3, 11, 1, 9,
        15, 7, 13, 5
    ]

    static func sampleBayer2x2(x: Int, y: Int, b: Float) -> Graphics.Color {
        let t = UInt8(min(max(b, 0), 1) * 4)
        let i = ((y & 1) << 1) | (x & 1)
        return bayer2x2Matrix[i] < t ? .white : .black
    }

    static func sampleBayer4x4(x: Int, y: Int, b: Float) -> Graphics.Color {
        let t = UInt8(min(max(b, 0), 1) * 16)
        let i = ((y & 3) << 2) | (x & 3)
        let v = bayer4x4Matrix[i]
        return v < t ? .white : .black
    }
}
