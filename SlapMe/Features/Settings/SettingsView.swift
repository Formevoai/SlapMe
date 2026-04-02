import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var storeManager: StoreManager
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
                        Label("Seçili Paket", systemImage: "music.note.list")
                        Spacer()
                        Text(settingsStore.settings.selectedPackID.capitalized)
                            .foregroundStyle(.secondary)
                    }
                } header: { Text("Ses Paketi") }

                // Hassasiyet
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hassasiyet", systemImage: "waveform")
                        HStack {
                            Text("Düşük")
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: s.sensitivity, in: 0.1...1.0, step: 0.05)
                            Text("Yüksek")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cooldown", systemImage: "timer")
                        HStack {
                            Text("Hızlı")
                                .font(.caption).foregroundStyle(.secondary)
                            Slider(value: s.cooldown, in: 0.3...3.0, step: 0.1)
                            Text("Yavaş")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(String(format: "%.1f saniye", settingsStore.settings.cooldown))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: { Text("Algılama") }

                // Ses
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Ana Ses", systemImage: "speaker.wave.2")
                        Slider(value: s.masterVolume, in: 0.0...1.0, step: 0.05)
                    }

                    Toggle(isOn: s.dynamicVolume) {
                        Label("Dinamik Ses", systemImage: "waveform.path.ecg")
                    }
                } header: { Text("Ses") }

                // Görsel & Haptik
                Section {
                    Toggle(isOn: s.hapticsEnabled) {
                        Label("Titreşim", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    Toggle(isOn: s.screenFlashEnabled) {
                        Label("Ekran Flaşı", systemImage: "bolt.fill")
                    }
                    Toggle(isOn: s.chargerSoundEnabled) {
                        Label("Şarj Sesi", systemImage: "bolt.fill.batteryblock")
                    }
                    if settingsStore.settings.chargerSoundEnabled {
                        Text("Şarj kablosu takılınca seçtiğin karakterden rastgele bir ses çalar ⚡")
                            .font(.caption).foregroundStyle(.secondary)

                        ForEach(categories) { category in
                            DisclosureGroup {
                                ForEach(category.packs) { pack in
                                    let locked = isChargerPackLocked(category: category, pack: pack)
                                    let selected = settingsStore.settings.chargerSoundPackID == pack.id
                                    let isFreeSexy = category.id == "sexy" && pack.id == category.packs.first?.id

                                    Button {
                                        if !locked {
                                            settingsStore.settings.chargerSoundPackID = pack.id
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(pack.title)
                                                .foregroundColor(locked ? .secondary : .primary)
                                            if isFreeSexy && !storeManager.isPremium {
                                                Text("ÜCRETSİZ")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.green)
                                            }
                                            if locked {
                                                Spacer()
                                                Image(systemName: "lock.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.orange)
                                                Text("PRO")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.orange)
                                            }
                                            Spacer()
                                            if selected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    .disabled(locked)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                    Text(category.title)
                                    if category.id == "yamete" && !storeManager.isPremium {
                                        Text("PRO")
                                            .font(.caption2.bold())
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }

                        if isChargerPackTrial() {
                            Text("🔒 Deneme: Bu karakterden sadece 1 ses çalar. Tüm sesler için PRO'ya geç!")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                } header: { Text("Geri Bildirim") }

                // Güvenlik
                Section {
                    Toggle(isOn: s.safeModeEnabled) {
                        Label("Güvenli Mod", systemImage: "shield.fill")
                    }
                    if settingsStore.settings.safeModeEnabled {
                        Text("Uygulama arka planda iken tetiklenme engellenir.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: { Text("Güvenlik") }

                // Görünüm
                Section {
                    Toggle(isOn: s.darkMode) {
                        Label("Koyu Tema", systemImage: "moon.fill")
                    }
                } header: { Text("Görünüm") }

                // Yasal & Hesap
                Section {
                    Link(destination: URL(string: "https://eminsahan.github.io/SlapMe/privacy-policy.html")!) {
                        Label("Gizlilik Politikası", systemImage: "hand.raised.fill")
                    }

                    Button {
                        Task { await storeManager.restore() }
                    } label: {
                        Label("Satın Alımları Geri Yükle", systemImage: "arrow.clockwise")
                    }
                } header: { Text("Yasal") }


            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }

        }
    }

    // MARK: - Charger pack lock helpers

    /// Sexy: sadece ilk karakter free, geri kalan locked. Yamete: tamamen locked.
    private func isChargerPackLocked(category: SoundCategory, pack: SoundPack) -> Bool {
        guard !storeManager.isPremium else { return false }
        if category.id == "yamete" { return true }
        if category.id == "sexy" { return pack.id != category.packs.first?.id }
        return false
    }

    /// Seçili pack sexy'nin free karakteri ise (PRO değilse) → trial (1 ses)
    private func isChargerPackTrial() -> Bool {
        guard !storeManager.isPremium else { return false }
        let packID = settingsStore.settings.chargerSoundPackID
        guard let category = categories.first(where: { $0.packs.contains(where: { $0.id == packID }) }) else { return false }
        return category.id == "sexy" && packID == category.packs.first?.id
    }
}
