import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var localizationManager: LocalizationManager = .shared
    let categories: [SoundCategory]
    @Environment(\.dismiss) private var dismiss

    private var s: Binding<AppSettings> { $settingsStore.settings }

    private var allPacks: [SoundPack] {
        categories.flatMap { $0.packs }
    }

    var body: some View {
        NavigationView {
            Form {
                // Seçili Pack
                Section {
                    HStack {
                        Label(L("settings_selected_pack"), systemImage: "music.note.list")
                        Spacer()
                        Text(settingsStore.settings.selectedPackID.capitalized)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L("section_sound_pack"))
                }

                // Hassasiyet
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L("settings_sensitivity"), systemImage: "waveform")
                        HStack {
                            Text(L("sensitivity_low"))
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: s.sensitivity, in: 0.1...1.0, step: 0.05)
                            Text(L("sensitivity_high"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label(L("settings_cooldown"), systemImage: "timer")
                        HStack {
                            Text(L("cooldown_fast"))
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: s.cooldown, in: 0.3...3.0, step: 0.1)
                            Text(L("cooldown_slow"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(L("cooldown_seconds_format", settingsStore.settings.cooldown))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L("section_detection"))
                }

                // Ses
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L("settings_master_volume"), systemImage: "speaker.wave.2")
                        Slider(value: s.masterVolume, in: 0.0...1.0, step: 0.05)
                    }

                    Toggle(isOn: s.dynamicVolume) {
                        Label(L("settings_dynamic_volume"), systemImage: "waveform.path.ecg")
                    }
                } header: {
                    Text(L("section_sound"))
                }

                // Görsel & Haptik
                Section {
                    Toggle(isOn: s.hapticsEnabled) {
                        Label(
                            L("settings_haptics"), systemImage: "iphone.radiowaves.left.and.right")
                    }
                    Toggle(isOn: s.screenFlashEnabled) {
                        Label(L("settings_screen_flash"), systemImage: "bolt.fill")
                    }
                    Toggle(isOn: s.chargerSoundEnabled) {
                        Label(L("settings_charger_sound"), systemImage: "bolt.fill.batteryblock")
                    }
                    if settingsStore.settings.chargerSoundEnabled {
                        Text(L("charger_sound_description"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L("section_feedback"))
                }

                // Güvenlik
                Section {
                    Toggle(isOn: s.safeModeEnabled) {
                        Label(L("settings_safe_mode"), systemImage: "shield.fill")
                    }
                    if settingsStore.settings.safeModeEnabled {
                        Text(L("safe_mode_explanation"))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text(L("section_security"))
                }

                // Yasal & Hesap
                // Language
                Section {
                    Picker(L("settings_language"), selection: $localizationManager.selectedLanguage)
                    {
                        ForEach(LocalizationManager.supportedLanguages, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                } header: {
                    Text(L("section_language"))
                }

                Section {
                    Link(
                        destination: URL(
                            string: "https://formevoai.github.io/SlapMe/privacy-policy.html")!
                    ) {
                        Label(L("settings_privacy_policy"), systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        DisclaimerView()
                    } label: {
                        Label(
                            L("settings_disclaimer"), systemImage: "exclamationmark.triangle.fill")
                    }

                    Button {
                        Task { await storeManager.restore() }
                    } label: {
                        Label(L("settings_restore_purchases"), systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text(L("section_legal"))
                }

            }
            .navigationTitle(L("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button_done")) { dismiss() }
                }
            }

        }
    }

}
