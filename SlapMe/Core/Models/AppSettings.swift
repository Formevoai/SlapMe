import Foundation

struct AppSettings: Codable, Equatable {
    var sensitivity: Double       // 0.1 ... 1.0
    var cooldown: Double          // 0.3 ... 3.0 saniye
    var masterVolume: Double      // 0.0 ... 1.0
    var dynamicVolume: Bool
    var hapticsEnabled: Bool
    var screenFlashEnabled: Bool
    var safeModeEnabled: Bool
    var selectedPackID: String
    var chargerSoundEnabled: Bool
    var chargerSoundPackID: String

    static let `default` = AppSettings(
        sensitivity: 0.5,
        cooldown: 0.8,
        masterVolume: 1.0,
        dynamicVolume: true,
        hapticsEnabled: true,
        screenFlashEnabled: true,
        safeModeEnabled: false,
        selectedPackID: "alice",
        chargerSoundEnabled: true,
        chargerSoundPackID: "alice"
    )
}
