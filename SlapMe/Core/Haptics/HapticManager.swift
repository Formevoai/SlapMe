import CoreHaptics
import Foundation

final class HapticManager {
    private var engine: CHHapticEngine?
    var isEnabled: Bool = true

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()

        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        engine?.stoppedHandler = { _ in }
    }

    func play(for event: ImpactEvent) {
        guard isEnabled,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine else { return }

        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: Float(max(0.2, event.intensity))
        )
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: event.level == .hard ? 0.9 : 0.5
        )

        let hapticEvent = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        guard let pattern = try? CHHapticPattern(events: [hapticEvent], parameters: []),
              let player = try? engine.makePlayer(with: pattern)
        else { return }

        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
