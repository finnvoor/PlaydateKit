import PlaydateKit

class Goto: Sprite.Sprite {
    // MARK: Lifecycle
    
    override init() {
        super.init()
        setSize(width: 140, height: 100)
        moveTo(Point(
            x: Display.width / 2,
            y: Display.height / 2
        ))
        setIgnoresDrawOffset(true)
    }

    // MARK: Public

    public var num: Int {
        return Int("\(nums[0])\(nums[1])\(nums[2])\(nums[3])")!
    }

    public func increment() {
        nums[selectedNumIndex] = (nums[selectedNumIndex] + 1) % 10
    }

    public func decrement() {
        nums[selectedNumIndex] = (nums[selectedNumIndex] - 1 + 10) % 10
    }

    public func selectNextNum() {
        selectedNumIndex = (selectedNumIndex + 1) % 4
    }

    public func selectPreviousNum() {
        selectedNumIndex = (selectedNumIndex - 1 + 4) % 4
    }

    // MARK: Internal

    override func draw(bounds _: Rect, drawRect _: Rect) {
        Graphics.fillRoundRect(bounds, radius: 3, color: .black)

        Graphics.drawRoundRect(
            bounds.insetBy(dx: Float(Self.padding), dy: Float(Self.padding)),
            radius: 0,
            lineWidth: 2,
            color: .white
        )

        let boundsTl = Point(x: bounds.x, y: bounds.y)

        // Numbers
        for (i, num) in nums.enumerated() {
            drawNum(num, at: boundsTl + Point(x: 15 + (i * 30), y: Self.padding * 4))
        }

        // Selected number triangles
        let triXOff = 15 + 4 + selectedNumIndex * 30

        Graphics.fillTriangle(
            p1: boundsTl + Point(x: 0 + triXOff, y: 20),
            p2: boundsTl + Point(x: 10 + triXOff, y: 20),
            p3: boundsTl + Point(x: 5 + triXOff, y: 15),
            color: .white,
        )

        Graphics.fillTriangle(
            p1: boundsTl + Point(x: 0 + triXOff, y: 52),
            p2: boundsTl + Point(x: 5 + triXOff, y: 58),
            p3: boundsTl + Point(x: 10 + triXOff, y: 52),
            color: .white,
        )

        // Nav text
        Graphics.setFont(Font.NicoPups16)
        Graphics.drawMode = .fillWhite

        Graphics.drawText("Ⓑ Cancel", at: Point(
            x: Int(bounds.x) + Self.padding * 2,
            y: Int(bounds.maxY) - Font.NicoPups16.height - Self.padding - 2
        ))

        Graphics.drawTextInRect("Ⓐ Go", in: Rect(
            x: bounds.x,
            y: bounds.maxY - Float(Font.NicoPups16.height) - Float(Self.padding) - 2,
            width: bounds.width - Float(Self.padding * 2),
            height: 20,
        ), aligned: .right)
    }

    // MARK: Private

    private static let padding = 6

    private var nums: [Int] = [
        Int.random(in: 1...2),
        Int.random(in: 1...9),
        Int.random(in: 1...9),
        Int.random(in: 1...9),
    ]

    private var selectedNumIndex: Int = 0

    private func drawNum(_ num: Int, at: Point) {
        Graphics.fillRect(Rect(
            x: at.x,
            y: at.y,
            width: 18,
            height: 24,
        ), color: .white)

        Graphics.drawMode = .fillBlack
        Graphics.setFont(Font.NicoClean16)
        Graphics.drawText("\(num)", at: at + Point(
            x: 4,
            y: 6,
        ))
    }
}
