import UIKit

final class HapticManager {
    var isEnabled: Bool = true

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    func play(for event: ImpactEvent) {
        guard isEnabled else { return }
        let intensity = CGFloat(max(0.2, event.intensity))
        switch event.level {
        case .hard, .combo:
            heavyGenerator.impactOccurred(intensity: intensity)
            heavyGenerator.prepare()
        case .medium:
            mediumGenerator.impactOccurred(intensity: intensity)
            mediumGenerator.prepare()
        case .soft:
            lightGenerator.impactOccurred(intensity: intensity)
            lightGenerator.prepare()
        }
    }
}
