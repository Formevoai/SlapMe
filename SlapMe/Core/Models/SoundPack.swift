import Foundation

/// Bir karakteri + seslerini temsil eder.
/// JSON'dan doğrudan decode edilmez — SoundCategoryLoader tarafından SoundCategory'den üretilir.
struct SoundPack: Identifiable {
    let id: String           // karakter ID'si, ör. "alice", "classic"
    let title: String        // karakter adı, ör. "Alice"
    let categoryID: String   // üst kategori, ör. "sexy", "classic"
    let soundFolder: String  // Bundle'daki Sounds/ altındaki klasör
    let isPremium: Bool
    let themeColor: String   // hex renk
    let comingSoon: Bool
    let softClips: [String]
    let mediumClips: [String]
    let hardClips: [String]
    let comboClips: [String]
    let previewClip: String
}
