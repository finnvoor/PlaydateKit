import PlaydateKit

class Goto: Sprite.Sprite {
    // MARK: Lifecycle
    
    override init() {
        super.init()
        setSize(width: 140, height: 90)
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
        Graphics.fillRect(bounds, color: .black(opacity: 0.75))

        let boundsTl = Point(x: bounds.x, y: bounds.y)

        // Numbers
        for (i, num) in nums.enumerated() {
            drawNum(num, at: boundsTl + Point(x: 10 + (i * 20), y: 20))
        }

        // Selected number triangles
        let triXOff = selectedNumIndex * 20

        Graphics.fillTriangle(
            p1: boundsTl + Point(x: 15 + triXOff, y: 15),
            p2: boundsTl + Point(x: 25 + triXOff, y: 15),
            p3: boundsTl + Point(x: 20 + triXOff, y: 10),
            color: .white,
        )

        Graphics.fillTriangle(
            p1: boundsTl + Point(x: 15 + triXOff, y: 50),
            p2: boundsTl + Point(x: 20 + triXOff, y: 55),
            p3: boundsTl + Point(x: 25 + triXOff, y: 50),
            color: .white,
        )

        // Bottom bar
        Graphics.fillRect(Rect(
            x: bounds.x,
            y: bounds.maxY - 20,
            width: bounds.width,
            height: 20,
        ), color: .black)

        Graphics.drawText("Ⓑ Cancel", at: Point(
            x: bounds.x + 5,
            y: bounds.maxY - 20
        ))

        Graphics.drawTextInRect("Ⓐ Go", in: Rect(
            x: bounds.x,
            y: bounds.maxY - 20,
            width: bounds.width - 5,
            height: 20,
        ), aligned: .right)
    }

    // MARK: Private

    private var nums: [Int] = [
        Int.random(in: 1...2, using: &RNG.instance),
        Int.random(in: 1...9, using: &RNG.instance),
        Int.random(in: 1...9, using: &RNG.instance),
        Int.random(in: 1...9, using: &RNG.instance),
    ]

    private var selectedNumIndex: Int = 0

    private func drawNum(_ num: Int, at: Point) {
        Graphics.fillRect(Rect(
            x: at.x,
            y: at.y,
            width: 18,
            height: 24,
        ), color: .black)

        Graphics.drawMode = .fillWhite
        Graphics.drawText("\(num)", at: at + Point(
            x: 6,
            y: 4,
        ))
    }
}
