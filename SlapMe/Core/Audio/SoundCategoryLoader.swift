import Foundation

final class SoundCategoryLoader {

    /// Şu an devre dışı bırakılan kategoriler — silmeden gizlemek için.
    private static let disabledIDs: Set<String> = ["classic", "gentleman", "pain"]

    static func loadAll() -> [SoundCategory] {
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Packs") ?? []
        return urls
            .compactMap { url -> SoundCategory? in
                guard let data = try? Data(contentsOf: url),
                      let file = try? JSONDecoder().decode(SoundCategoryFile.self, from: data)
                else {
                    print("[SoundCategoryLoader] JSON yüklenemedi: \(url.lastPathComponent)")
                    return nil
                }
                if disabledIDs.contains(file.id) { return nil }
                return category(from: file)
            }
            .sorted { lhs, rhs in
                // Ücretsizler önce
                if lhs.isPremium != rhs.isPremium { return !lhs.isPremium }
                return lhs.id < rhs.id
            }
    }

    private static func category(from file: SoundCategoryFile) -> SoundCategory {
        let packs = file.characters.map { char in
            SoundPack(
                id: char.id,
                title: char.name,
                categoryID: file.id,
                soundFolder: file.soundFolder,
                isPremium: file.isPremium,
                themeColor: file.themeColor,
                comingSoon: char.comingSoon ?? false,
                softClips: char.softClips,
                mediumClips: char.mediumClips,
                hardClips: char.hardClips,
                comboClips: char.comboClips ?? [],
                previewClip: char.previewClip
            )
        }
        return SoundCategory(
            id: file.id,
            title: file.title,
            icon: file.icon,
            isPremium: file.isPremium,
            packs: packs
        )
    }
}
