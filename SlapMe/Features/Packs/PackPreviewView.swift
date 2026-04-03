import SwiftUI

struct PackPreviewView: View {
    let pack: SoundPack
    @ObservedObject var audioManager: AudioManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    var onSelect: () -> Void
    var onDismiss: () -> Void

    @State private var isPlaying = false

    var body: some View {
        VStack(spacing: 24) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // Karakter emoji
            Text(characterEmoji)
                .font(.system(size: 80))
                .scaleEffect(isPlaying ? 1.3 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.4), value: isPlaying)

            // Pack bilgisi
            VStack(spacing: 6) {
                HStack {
                    Text(pack.title)
                        .font(.title2.bold())
                    if pack.isPremium {
                        Text(L("pro_badge"))
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.85))
                            .clipShape(Capsule())
                    }
                }
                Text(pack.title)
                    .foregroundStyle(.secondary)
            }

            // Clip sayısı
            HStack(spacing: 24) {
                statItem(label: L("clip_level_soft"), count: pack.softClips.count)
                statItem(label: L("clip_level_medium"), count: pack.mediumClips.count)
                statItem(label: L("clip_level_hard"), count: pack.hardClips.count)
                statItem(label: L("clip_level_combo"), count: pack.comboClips.count)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()

            // Butonlar
            VStack(spacing: 12) {
                Button(action: {
                    isPlaying = true
                    audioManager.playPreview(pack: pack)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isPlaying = false }
                }) {
                    Label(L("button_preview"), systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button(action: onSelect) {
                    Text(L("button_select_pack"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding(.horizontal)
    }

    private var characterEmoji: String {
        switch pack.categoryID {
        case "goat": return "🐐"
        case "yamete": return "😳"
        case "sexy": return "😏"
        case "funny": return "😂"
        case "pain": return "😱"
        case "gentleman": return "🎩"
        default: return "😐"
        }
    }

    private func statItem(label: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
