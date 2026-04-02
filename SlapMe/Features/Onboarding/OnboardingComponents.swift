import SwiftUI

// MARK: - Accent gradient used across onboarding

let onboardingAccent = LinearGradient(
    colors: [Color(red: 1.0, green: 0.55, blue: 0.2), Color(red: 1.0, green: 0.35, blue: 0.4)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// MARK: - Clean light background with subtle glow

struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.orange.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Page indicator dots (4 pages)

struct OnboardingPageIndicator: View {
    let currentPage: Int
    private let totalPages = 4

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? AnyShapeStyle(onboardingAccent)
                          : AnyShapeStyle(Color.black.opacity(0.12)))
                    .frame(
                        width: index == currentPage ? 24 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}

// MARK: - Onboarding CTA Button

struct OnboardingButton: View {
    let title: String
    var isActive: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isActive
                    ? AnyShapeStyle(onboardingAccent)
                    : AnyShapeStyle(Color.gray.opacity(0.2))
                )
                .foregroundColor(isActive ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: isActive ? Color.orange.opacity(0.3) : .clear, radius: 12, y: 4)
        }
        .disabled(!isActive)
        .padding(.horizontal, 32)
    }
}
