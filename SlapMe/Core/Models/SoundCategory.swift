import Foundation

/// Birden fazla karakteri gruplayan kategori (ör. "Sexy", "Animals").
/// Kategorinin tüm karakterleri aynı `soundFolder`'ı paylaşır.
struct SoundCategory: Identifiable {
    let id: String
    let title: String
    let icon: String  // SF Symbol adı
    let isPremium: Bool
    let packs: [SoundPack]
}

// MARK: - JSON DTO'ları (Loader tarafından kullanılır)

struct SoundCategoryFile: Codable {
    let id: String
    let title: String
    let icon: String
    let isPremium: Bool
    let soundFolder: String
    let themeColor: String
    let characters: [CharacterEntry]

    struct CharacterEntry: Codable {
        let id: String
        let name: String
        let comingSoon: Bool?
        let softClips: [String]?
        let mediumClips: [String]?
        let hardClips: [String]?
        let comboClips: [String]?
        let clips: [String]?
        let previewClip: String
    }
}
