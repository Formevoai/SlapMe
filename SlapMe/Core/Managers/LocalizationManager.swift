import Foundation
import SwiftUI

/// Manages in-app language override. When `selectedLanguage` is nil, system default is used.
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    /// Supported language codes
    static let supportedLanguages: [(code: String, name: String)] = [
        ("system", "System"),
        ("en",      "English"),
        ("tr",      "Türkçe"),
        ("de",      "Deutsch"),
        ("es",      "Español"),
        ("fr",      "Français"),
        ("pt-BR",   "Português (BR)"),
        ("it",      "Italiano"),
        ("nl",      "Nederlands"),
        ("ru",      "Русский"),
        ("ja",      "日本語"),
        ("ko",      "한국어"),
        ("zh-Hans", "中文(简体)"),
        ("ar",      "العربية"),
        ("hi",      "हिन्दी"),
        ("pl",      "Polski"),
        ("id",      "Bahasa Indonesia")
    ]

    @AppStorage("app_language") var selectedLanguage: String = "system" {
        didSet { objectWillChange.send() }
    }

    private var bundle: Bundle {
        if selectedLanguage == "system" {
            return .main
        }
        guard let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: args)
    }
}

// Global shortcut
func L(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let format = LocalizationManager.shared.localized(key)
    return String(format: format, arguments: args)
}
