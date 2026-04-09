import Foundation

struct CustomPack: Codable, Identifiable {
    var id: String
    var name: String
    var clips: [String]  // Documents/CustomSounds/{id}/ altındaki dosya adları
    var previewClip: String?  // nil ise clips.first kullanılır
    var themeColor: String = "#7C4DFF"
    var createdAt: Date = .init()
}
