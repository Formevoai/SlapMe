import SwiftUI
import StoreKit

struct StoreView: View {
    let categories: [SoundCategory]
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.12),
                        Color(red: 0.08, green: 0.03, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // PRO banner (if not purchased)
                        if !storeManager.isPremium {
                            proBanner
                                .padding(.top, 8)
                        }

                        // All categories
                        ForEach(categories) { category in
                            CategoryStoreCard(
                                category: category,
                                settingsStore: settingsStore,
                                audioManager: audioManager,
                                isPremium: storeManager.isPremium,
                                onSelectPack: selectAndDismiss
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .preferredColorScheme(.light)
            .navigationTitle(L("store_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("button_close")) { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - PRO Banner

    private var proBanner: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text("SlapMe PRO")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(L("store_pro_subtitle"))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.6))

            // Features
            VStack(alignment: .leading, spacing: 8) {
                proFeatureRow(icon: "speaker.wave.3.fill", text: L("feature_all_premium_sounds"))
                proFeatureRow(icon: "person.3.fill", text: L("feature_all_characters"))
                proFeatureRow(icon: "infinity", text: L("feature_one_time_payment"))
                proFeatureRow(icon: "arrow.up.circle.fill", text: L("feature_future_updates"))
            }
            .padding(.vertical, 8)

            // Buy button
            Button {
                Task { await storeManager.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(storeManager.isPurchasing ? L("purchasing_in_progress") : "\(L("upgrade_to_pro")) — \(storeManager.priceText)")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(storeManager.isPurchasing)

            // Restore
            Button {
                Task { await storeManager.restore() }
            } label: {
                Text(L("restore_purchases"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.4), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func proFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.purple)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func selectAndDismiss(_ pack: SoundPack) {
        settingsStore.settings.selectedPackID = pack.id
        dismiss()
    }
}

// MARK: - Category Card

private struct CategoryStoreCard: View {
    let category: SoundCategory
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var audioManager: AudioManager
    let isPremium: Bool
    let onSelectPack: (SoundPack) -> Void

    @State private var isExpanded = false

    private var isFullyUnlocked: Bool {
        !category.isPremium || isPremium
    }

    /// Sexy: ilk karakter free, geri kalanı PRO. Yamete: hepsi PRO. Free kategoriler: hepsi açık.
    private func isPackLocked(_ pack: SoundPack) -> Bool {
        guard !isPremium else { return false }
        if category.id == "yamete" { return true }
        if category.id == "sexy" { return pack.id != category.packs.first?.id }
        return false
    }

    private var isCategoryActive: Bool {
        category.packs.contains { $0.id == settingsStore.settings.selectedPackID }
    }

    private var hasMultiplePacks: Bool {
        category.packs.count > 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(isCategoryActive ? .purple : .white.opacity(0.7))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(category.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        if category.isPremium {
                            Text(L("pro_badge"))
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.black)
                                .clipShape(Capsule())
                        }
                    }
                    Text(category.packs.count == 1
                         ? category.packs[0].title
                         : L("character_count_format", category.packs.count))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                if hasMultiplePacks {
                    // Multi pack: always show expand arrow
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.4))
                } else if isFullyUnlocked {
                    // Single pack unlocked: preview + select
                    Button { audioManager.playPreview(pack: category.packs[0]) } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: isCategoryActive ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isCategoryActive ? .purple : .white.opacity(0.3))
                        .onTapGesture { onSelectPack(category.packs[0]) }
                } else {
                    // Single pack locked
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                if hasMultiplePacks {
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                } else if isFullyUnlocked {
                    onSelectPack(category.packs[0])
                }
            }

            // Expanded character list
            if isExpanded && hasMultiplePacks {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal)

                ForEach(category.packs) { pack in
                    let isActive = settingsStore.settings.selectedPackID == pack.id
                    let locked = isPackLocked(pack)
                    let isFreeOne = category.isPremium && !isPremium && !locked

                    HStack(spacing: 12) {
                        Color.clear.frame(width: 28)

                        Text(pack.title)
                            .font(.subheadline)
                            .foregroundColor(locked ? .white.opacity(0.35) : .white.opacity(0.8))

                        if isFreeOne {
                            Text(L("free_badge"))
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }

                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.orange.opacity(0.6))
                        }

                        Spacer()

                        if !locked {
                            Button { audioManager.playPreview(pack: pack) } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .buttonStyle(.plain)

                            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(isActive ? .purple : .white.opacity(0.3))
                                .onTapGesture { onSelectPack(pack) }
                        } else {
                            Image(systemName: "lock.circle")
                                .font(.title2)
                                .foregroundColor(.orange.opacity(0.3))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    if pack.id != category.packs.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isCategoryActive
                      ? Color.purple.opacity(0.15)
                      : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isCategoryActive ? Color.purple.opacity(0.5) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
}

