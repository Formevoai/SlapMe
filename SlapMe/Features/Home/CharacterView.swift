import SwiftUI

struct CharacterView: View {
    let pack: SoundPack
    let isReacting: Bool
    let intensity: Double
    let isLocked: Bool
    var isBackground: Bool = false
    var isComingSoon: Bool = false
    var onLockTap: (() -> Void)? = nil
    var onAddNewTap: (() -> Void)? = nil
    var isAtPackLimit: Bool = false
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var breathe: CGFloat = 1.0
    @State private var impactShake: CGFloat = 0

    private var characterImage: UIImage? {
        let filename = "char_\(pack.id)"
        if let img = UIImage(named: filename) { return img }
        if let url = Bundle.main.url(
            forResource: filename, withExtension: "png", subdirectory: "Characters"),
            let img = UIImage(contentsOfFile: url.path)
        {
            return img
        }
        if let url = Bundle.main.url(forResource: filename, withExtension: "png"),
            let img = UIImage(contentsOfFile: url.path)
        {
            return img
        }
        return nil
    }

    private var cardBg: Color { .white }

    private var tagColor: Color {
        switch pack.categoryID {
        case "sexy": return Color(red: 1, green: 0.4, blue: 0.7)
        case "yamete": return Color(red: 0.85, green: 0.35, blue: 0.55)
        case "goat": return Color(red: 1, green: 0.55, blue: 0.65)
        case "funny": return Color(red: 0.4, green: 0.75, blue: 0.3)
        case "custom": return Color.purple
        default: return .gray
        }
    }

    private var tagText: String {
        switch pack.categoryID {
        case "sexy": return L("tag_sexy")
        case "yamete": return L("tag_yamete")
        case "goat": return L("tag_animal")
        case "funny": return L("tag_funny")
        case "custom": return "Custom"
        default: return pack.categoryID.capitalized
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Character image
            if pack.id == "custom_add_new" {
                // "Ekle" slotu - ses paketi görseli
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.18), Color.indigo.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: "waveform.badge.microphone")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.7), Color.indigo.opacity(0.7),
                                        ],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        }
                        Text(L("custom_add_slot_hint"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.purple.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.top, 12)
            } else if pack.isCustom {
                // Custom karakter: ses dalgası placeholder
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.25), Color.purple.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.purple.opacity(0.6))
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 12)
                .padding(.top, 12)
            } else if let uiImage = characterImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(fallbackEmoji)
                    .font(.system(size: 52))
                    .frame(height: 160)
            }

            // Name + tag row
            HStack(spacing: 6) {
                Text(pack.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(white: 0.15))
                    .lineLimit(1)

                Text(tagText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tagColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tagColor.opacity(0.12), in: Capsule())

                Spacer()

                if !pack.clips.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(pack.clips.count)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(white: 0.3).opacity(0.75), in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(cardBg)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(
            color: .black.opacity(0.08),
            radius: isBackground ? 6 : 12,
            y: isBackground ? 2 : 4
        )
        .overlay(
            ZStack {
                if pack.id == "custom_add_new" && !isLocked && isAtPackLimit {
                    // Limit doldu overlay
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.gray.opacity(0.5))
                        Text(
                            String(format: L("custom_pack_limit_title"), CustomPackManager.maxPacks)
                        )
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.4))
                        Text(L("custom_pack_limit_desc"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pack.id == "custom_add_new" && !isLocked {
                    // Pro kullanıcı: yeni ses paketi ekle
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.purple.opacity(0.05))
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.purple.opacity(0.75))
                        Text(L("custom_add_slot_title"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(white: 0.2))
                        Text(L("custom_add_slot_desc"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { onAddNewTap?() }
                } else if isComingSoon {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.black.opacity(0.5))

                    VStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.9))
                        Text(L("coming_soon"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                } else if isLocked {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.black.opacity(pack.id == "custom_add_new" ? 0.55 : 0.45))

                    VStack(spacing: pack.id == "custom_add_new" ? 6 : 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.9))
                        Text(L("pro_badge"))
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                        if pack.id == "custom_add_new" {
                            Text(L("custom_slot_locked_hint"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.top, 2)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onLockTap?() }
                }
            }
        )
        .scaleEffect(
            isReacting && !isBackground ? 1.0 + intensity * 0.15 : (isBackground ? 1.0 : breathe)
        )
        .offset(x: isReacting && !isBackground ? impactShake : 0)
        .rotationEffect(.degrees(isReacting && !isBackground ? Double(impactShake) * 0.4 : 0))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tagColor.opacity(isReacting && !isBackground ? 0.7 : 0), lineWidth: 3)
                .scaleEffect(isReacting && !isBackground ? 1.02 : 1.0)
                .animation(.easeOut(duration: 0.3), value: isReacting)
        )
        .shadow(
            color: isReacting && !isBackground ? tagColor.opacity(0.5) : .clear,
            radius: isReacting ? 20 : 0, y: 0
        )
        .animation(.interpolatingSpring(stiffness: 400, damping: 10), value: isReacting)
        .onChange(of: isReacting) { reacting in
            guard reacting, !isBackground else { return }
            // Shake sequence
            let shakeValues: [CGFloat] = [12, -10, 8, -6, 4, -2, 0]
            for (i, val) in shakeValues.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                    withAnimation(.linear(duration: 0.04)) { impactShake = val }
                }
            }
        }
        .onAppear {
            if !isBackground {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    breathe = 1.012
                }
            }
        }
    }

    private var fallbackEmoji: String {
        switch pack.categoryID {
        case "goat": return "🐐"
        case "yamete": return "😳"
        case "sexy": return "😏"
        case "funny": return "😂"
        case "custom": return "🎵"
        default: return "😐"
        }
    }
}
