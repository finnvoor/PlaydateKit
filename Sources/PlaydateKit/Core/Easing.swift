public enum Easing {
    case linear
    case inSine
    case outSine
    case inOutSine
    case inQuad
    case outQuad
    case inOutQuad
    case inCubic
    case outCubic
    case inOutCubic
    case inQuart
    case outQuart
    case inOutQuart
    case inQuint
    case outQuint
    case inOutQuint
    case inExpo
    case outExpo
    case inOutExpo
    case inCirc
    case outCirc
    case inOutCirc
    case inBack
    case outBack
    case inOutBack
    case inElastic
    case outElastic
    case inOutElastic
    case inBounce
    case outBounce
    case inOutBounce

    // MARK: Public

    public func ease(_ value: Float, duration: Float = 1, scale: ClosedRange<Float> = 0...1) -> Float {
        var x = value.scaled(from: 0...duration, to: 0...1)
            .clamped(to: 0...1)
        let ease = {
            switch self {
            case .linear:
                return x
            case .inSine:
                return 1 - cosf((x * Float.pi) / 2)
            case .outSine:
                return sinf((x * Float.pi) / 2)
            case .inOutSine:
                return -(cosf(Float.pi * x) - 1) / 2
            case .inQuad:
                return x * x
            case .outQuad:
                return 1 - (1 - x) * (1 - x)
            case .inOutQuad:
                return x < 0.5 ? 2 * x * x : 1 - powf(-2 * x + 2, 2) / 2
            case .inCubic:
                return x * x * x
            case .outCubic:
                return 1 - powf(1 - x, 3)
            case .inOutCubic:
                return x < 0.5 ? 4 * x * x * x : 1 - powf(-2 * x + 2, 3) / 2
            case .inQuart:
                return x * x * x * x
            case .outQuart:
                return 1 - powf(1 - x, 4)
            case .inOutQuart:
                return x < 0.5 ? 8 * x * x * x * x : 1 - powf(-2 * x + 2, 4) / 2
            case .inQuint:
                return x * x * x * x * x
            case .outQuint:
                return 1 - powf(1 - x, 5)
            case .inOutQuint:
                return x < 0.5 ? 16 * x * x * x * x * x : 1 - powf(-2 * x + 2, 5) / 2
            case .inExpo:
                return x == 0 ? 0 : powf(2, 10 * x - 10)
            case .outExpo:
                return x == 1 ? 1 : 1 - powf(2, -10 * x)
            case .inOutExpo:
                return x == 0 ? 0 : x == 1 ? 1 : x < 0.5 ? powf(2, 20 * x - 10) / 2 : 2 - powf(2, -20 * x + 10) / 2
            case .inCirc:
                return 1 - sqrtf(1 - powf(x, 2))
            case .outCirc:
                return sqrtf(1 - powf(x - 1, 2))
            case .inOutCirc:
                return x < 0.5 ? (1 - sqrtf(1 - powf(2 * x, 2))) / 2 : (sqrtf(1 - powf(-2 * x + 2, 2)) + 1) / 2
            case .inBack:
                let c1: Float = 1.70158
                let c3: Float = c1 + 1
                return c3 * x * x * x - c1 * x * x
            case .outBack:
                let c1: Float = 1.70158
                let c3: Float = c1 + 1
                return 1 + c3 * powf(x - 1, 3) + c1 * powf(x - 1, 2)
            case .inOutBack:
                let c1: Float = 1.70158
                let c2: Float = c1 * 1.525
                return x < 0.5 ? (powf(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2 : (powf(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
            case .inElastic:
                let c4: Float = (2 * Float.pi) / 3
                return x == 0 ? 0 : x == 1 ? 1 : -powf(2, 10 * x - 10) * sinf((x * 10 - 10.75) * c4)
            case .outElastic:
                let c4: Float = (2 * Float.pi) / 3
                return x == 0 ? 0 : x == 1 ? 1 : powf(2, -10 * x) * sinf((x * 10 - 0.75) * c4) + 1
            case .inOutElastic:
                let c5: Float = (2 * Float.pi) / 4.5
                return x == 0 ? 0 : x == 1 ? 1 : x < 0.5 ? -(powf(2, 20 * x - 10) * sinf((20 * x - 11.125) * c5)) / 2 : (powf(2, -20 * x + 10) * sinf((20 * x - 11.125) * c5)) / 2 + 1
            case .inBounce:
                return 1 - Easing.outBounce.ease(1 - x)
            case .outBounce:
                let n1: Float = 7.5625
                let d1: Float = 2.75

                if x < 1 / d1 {
                    return n1 * x * x
                } else if x < 2 / d1 {
                    x -= 1.5 / d1
                    return n1 * x * x + 0.75
                } else if x < 2.5 / d1 {
                    x -= 2.25 / d1
                    return n1 * x * x + 0.9375
                } else {
                    x -= 2.625 / d1
                    return n1 * x * x + 0.984375
                }
            case .inOutBounce:
                return x < 0.5 ? (1 - Easing.outBounce.ease(1 - 2 * x)) / 2 : (1 + Easing.outBounce.ease(2 * x - 1)) / 2
            }
        }()

        return ease.scaled(from: 0...1, to: scale)
    }
}
