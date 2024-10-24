public extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(min(self, range.upperBound), range.lowerBound)
    }
}

public extension Comparable where Self: FloatingPoint {
    func scaled(from inputRange: ClosedRange<Self>, to outputRange: ClosedRange<Self>) -> Self {
        (self - inputRange.lowerBound) * (outputRange.upperBound - outputRange.lowerBound) /
            (inputRange.upperBound - inputRange.lowerBound) + outputRange.lowerBound
    }
}
