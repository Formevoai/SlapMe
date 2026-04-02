import Foundation
import SwiftUI

struct Character: Codable, Identifiable {
    let id: String
    let name: String
    let packID: String
    let isPremium: Bool
    let themeColor: String  // hex
    let animationStyle: AnimationStyle

    enum AnimationStyle: String, Codable {
        case bounce
        case shake
        case spin
        case pulse
    }

    // SwiftUI Color dönüşümü
    var color: Color {
        Color(hex: themeColor) ?? .accentColor
    }
}

// MARK: - Built-in karakterler

extension Character {
    static let all: [Character] = [
        Character(id: "guy",          name: "Guy",          packID: "classic",   isPremium: false, themeColor: "#E87C2B", animationStyle: .shake),
        Character(id: "screamer",     name: "Screamer",     packID: "pain",      isPremium: false, themeColor: "#D93B3B", animationStyle: .shake),
        Character(id: "gremlin",      name: "Gremlin",      packID: "funny",     isPremium: false, themeColor: "#6DBE45", animationStyle: .bounce),
        Character(id: "goat_king",    name: "Goat King",    packID: "goat",      isPremium: false, themeColor: "#8B5E3C", animationStyle: .shake),
        Character(id: "sir_slap",     name: "Sir Slap",     packID: "gentleman", isPremium: false, themeColor: "#4A4A8A", animationStyle: .pulse),
        Character(id: "yumi",         name: "Yumi",         packID: "yamete",    isPremium: true,  themeColor: "#E8719A", animationStyle: .bounce),
        Character(id: "drama_queen",  name: "Drama Queen",  packID: "sexy",      isPremium: true,  themeColor: "#C2185B", animationStyle: .spin),
    ]

    static func forPack(_ packID: String) -> Character? {
        all.first { $0.packID == packID }
    }
}

// MARK: - Color hex init

private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int), hex.count == 6 else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
