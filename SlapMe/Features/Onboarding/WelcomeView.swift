import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var appeared = false
    @State private var handRotation: Double = -12
    @State private var handScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Animated hand SF Symbol
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(onboardingAccent)
                    .rotationEffect(.degrees(handRotation))
                    .scaleEffect(handScale)
                    .shadow(color: .orange.opacity(0.3), radius: 20)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            handRotation = 12
                        }
                    }
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .padding(.bottom, 28)

                // Title
                HStack(spacing: 0) {
                    Text("Slap")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                    Text("Me")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(onboardingAccent)
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)

                Text(L("welcome_subtitle"))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.45))
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer()

                // Page indicator
                OnboardingPageIndicator(currentPage: 0)
                    .padding(.bottom, 24)

                // CTA
                OnboardingButton(title: L("button_start"), action: onContinue)
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
