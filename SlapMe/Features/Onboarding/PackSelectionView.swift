import SwiftUI

struct PackSelectionView: View {
    var onFinish: (String) -> Void
    let categories: [SoundCategory]
    @ObservedObject var audioManager: AudioManager
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var selectedPackID: String = "alice"
    @State private var appeared = false

    // Flatten all non-comingSoon packs
    private var allPacks: [SoundPack] {
        categories.flatMap { $0.packs }.filter { !$0.comingSoon }
    }

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(L("pack_selection_title"))
                        .font(.title.bold())
                        .foregroundColor(.black)

                    Text(L("pack_selection_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.45))
                }
                .padding(.top, 52)
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // Character grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ],
                        spacing: 12
                    ) {
                        ForEach(allPacks) { pack in
                            CharacterThumbnail(
                                pack: pack,
                                isSelected: selectedPackID == pack.id,
                                onSelect: {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 18))
                                    {
                                        selectedPackID = pack.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .opacity(appeared ? 1 : 0)

                // Bottom area
                VStack(spacing: 16) {
                    OnboardingPageIndicator(currentPage: 3)

                    OnboardingButton(
                        title: L("button_start_exclamation"), action: { onFinish(selectedPackID) })
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Character Thumbnail Card

private struct CharacterThumbnail: View {
    let pack: SoundPack
    let isSelected: Bool
    let onSelect: () -> Void

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

    private var tagColor: Color {
        switch pack.categoryID {
        case "sexy": return Color(red: 1, green: 0.4, blue: 0.7)
        case "yamete": return Color(red: 0.85, green: 0.35, blue: 0.55)
        case "goat": return Color(red: 1, green: 0.55, blue: 0.65)
        case "funny": return Color(red: 0.4, green: 0.75, blue: 0.3)
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Character image
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.96))

                if let uiImage = characterImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.3))
                }

                // Selection checkmark
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, tagColor)
                                .shadow(color: .black.opacity(0.2), radius: 4)
                                .padding(6)
                        }
                        Spacer()
                    }
                }

                // PRO badge
                if pack.isPremium {
                    VStack {
                        HStack {
                            Text(L("pro_badge"))
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 5)
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
                                .padding(6)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? tagColor : Color.clear, lineWidth: 2.5)
            )

            // Name
            Text(pack.title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .black : .black.opacity(0.6))
                .lineLimit(1)
        }
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
