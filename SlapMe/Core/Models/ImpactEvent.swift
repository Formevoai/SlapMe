import Foundation

struct ImpactEvent {
    let timestamp: TimeInterval
    let magnitude: Double
    let intensity: Double  // 0.0 ... 1.0
    let level: ImpactLevel
    var comboCount: Int = 0

    enum ImpactLevel {
        case soft    // 0.0 ..< 0.4
        case medium  // 0.4 ..< 0.75
        case hard    // 0.75 ... 1.0
        case combo
    }
}
