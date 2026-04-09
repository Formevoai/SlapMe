import Combine
import Foundation

final class CustomPackManager: ObservableObject {
    @Published private(set) var packs: [CustomPack] = []

    private let storageKey = "custom_packs_v1"

    /// Documents/CustomSounds/ — tüm custom ses dosyları buraya kopyalanır
    static var customSoundsDir: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CustomSounds")
    }

    init() { load() }

    // MARK: - Yardımcı URL'ler

    func soundsDirectory(for packID: String) -> URL {
        Self.customSoundsDir.appendingPathComponent(packID)
    }

    func clipURL(filename: String, packID: String) -> URL {
        soundsDirectory(for: packID).appendingPathComponent(filename)
    }

    // MARK: - Pack CRUD

    @discardableResult
    func createPack(name: String) -> CustomPack {
        let pack = CustomPack(id: UUID().uuidString, name: name, clips: [])
        try? FileManager.default.createDirectory(
            at: soundsDirectory(for: pack.id), withIntermediateDirectories: true)
        packs.append(pack)
        save()
        return pack
    }

    func updateName(_ name: String, for packID: String) {
        guard let i = packs.firstIndex(where: { $0.id == packID }) else { return }
        packs[i].name = name
        save()
    }

    func deletePack(id packID: String) {
        try? FileManager.default.removeItem(at: soundsDirectory(for: packID))
        packs.removeAll { $0.id == packID }
        save()
    }

    // MARK: - Clip CRUD

    func addClip(from sourceURL: URL, to packID: String) throws {
        guard let i = packs.firstIndex(where: { $0.id == packID }) else { return }
        let dir = soundsDirectory(for: packID)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let filename = UUID().uuidString + "." + ext
        let dest = dir.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        packs[i].clips.append(filename)
        if packs[i].previewClip == nil { packs[i].previewClip = filename }
        save()
    }

    func removeClip(filename: String, from packID: String) {
        guard let i = packs.firstIndex(where: { $0.id == packID }) else { return }
        try? FileManager.default.removeItem(at: clipURL(filename: filename, packID: packID))
        packs[i].clips.removeAll { $0 == filename }
        if packs[i].previewClip == filename {
            packs[i].previewClip = packs[i].clips.first
        }
        save()
    }

    // MARK: - SoundPack / SoundCategory dönüşümü

    func toSoundPack(_ pack: CustomPack) -> SoundPack {
        SoundPack(
            id: pack.id,
            title: pack.name,
            categoryID: "custom",
            soundFolder: "",
            isPremium: true,
            themeColor: pack.themeColor,
            comingSoon: false,
            clips: pack.clips,
            previewClip: pack.previewClip ?? pack.clips.first ?? "",
            isCustom: true,
            customPackID: pack.id
        )
    }

    /// Carousel'e eklenecek kategori: mevcut karakterler + "Ekle" slotu
    var toSoundCategory: SoundCategory {
        let userPacks = packs.map { toSoundPack($0) }
        let addSlot = SoundPack(
            id: "custom_add_new",
            title: "Karakter Ekle",
            categoryID: "custom",
            soundFolder: "",
            isPremium: true,
            themeColor: "#7C4DFF",
            comingSoon: false,
            clips: [],
            previewClip: ""
        )
        return SoundCategory(
            id: "custom",
            title: "Benim Seslerim",
            icon: "person.badge.plus",
            isPremium: true,
            packs: userPacks + [addSlot]
        )
    }

    // MARK: - Kalıcılık

    private func save() {
        guard let data = try? JSONEncoder().encode(packs) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CustomPack].self, from: data)
        else { return }
        packs = decoded
    }
}
