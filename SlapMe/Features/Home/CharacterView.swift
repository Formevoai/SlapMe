import SwiftUI

struct CharacterView: View {
    let pack: SoundPack
    let isReacting: Bool
    let intensity: Double
    let isLocked: Bool
    var isBackground: Bool = false
    var isComingSoon: Bool = false
    var onLockTap: (() -> Void)? = nil
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
        default: return .gray
        }
    }

    private var tagText: String {
        switch pack.categoryID {
        case "sexy": return L("tag_sexy")
        case "yamete": return L("tag_yamete")
        case "goat": return L("tag_animal")
        case "funny": return L("tag_funny")
        default: return pack.categoryID.capitalized
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Character image — scaledToFit so full character is visible
            if let uiImage = characterImage {
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
                if isComingSoon {
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
                        .fill(.black.opacity(0.45))

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.9))
                        Text(L("pro_badge"))
                            .font(.caption.bold())
                            .foregroundColor(.orange)
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
        default: return "😐"
        }
    }
}
