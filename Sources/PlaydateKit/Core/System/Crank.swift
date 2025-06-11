public extension System {
    private nonisolated(unsafe) static var tick_lastCrankReading: Float = .infinity

    /// Returns the number of "ticks" — whose size is defined by the value of _ticksPerRevolution_ passed in to the function  — the crank has turned through since the last time this function was called. Ticks can be positive or negative, depending upon the direction of rotation. If the crank turns through more than one tick in-between update cycles, a value of 2 or more could be returned.
    /// An example: say you have a movie player, and you want your movie to advance 6 frames for every one revolution of the crank. Calling `playdate.getCrankTicks(6)` during each update will cause you to get a return value of 1 as the crank turns past each 60 degree increment (since we passed in a 6, each tick represents 360 / 6 = 60 degrees.) So `getCrankTicks(6)` will return a 1 as the crank turns past the 0 degree absolute position, the 60 degree absolute position, and so on for 120, 180, 240, and 300 degree positions. Otherwise, 0 will be returned.
    static func getCrankTicks(_ ticksPerRotation: Int) -> Int {
        let totalSegments = ticksPerRotation
        let degreesPerSegment = Float(360 / ticksPerRotation)

        let thisCrankReading = crankAngle
        if Self.tick_lastCrankReading == Float.infinity {
            tick_lastCrankReading = thisCrankReading
        }

        // if it seems we've gone more than halfway around the circle, that probably means we're seeing:
        // 1) a reversal in direction, not that the player is really cranking that fast. (a good assumption if fps is 20 or higher; maybe not as good if we're at 2 fps or similar.)
        // 2) a crossing of the 359->0 border, which gives the appearance of a massive crank change, but is really very small.
        // both these cases can be treated identically.
        let difference = thisCrankReading - tick_lastCrankReading
        if difference > 180 || difference < -180 {
            if tick_lastCrankReading >= 180 {
                // move tick_lastCrankReading back 360 degrees so it's < 0. It's the same location, just it is unequivocally lower than thisCrankReading
                tick_lastCrankReading -= 360
            } else {
                // move tick_lastCrankReading ahead 360 degrees so it's > 0. It's the same location, just now it is unequivocally greater than thisCrankReading.
                tick_lastCrankReading += 360
            }
        }

        // which segment is thisCrankReading in?
        let thisSegment = ceilf(thisCrankReading / degreesPerSegment)
        let lastSegment = ceilf(tick_lastCrankReading / degreesPerSegment)

        let segmentBoundariesCrossed = thisSegment - lastSegment

        // save off value
        tick_lastCrankReading = thisCrankReading

        return Int(segmentBoundariesCrossed)
    }
}
