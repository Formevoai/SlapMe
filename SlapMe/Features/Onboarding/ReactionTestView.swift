import SwiftUI

struct ReactionTestView: View {
    var onContinue: () -> Void
    @ObservedObject var motionManager: MotionManager
    @ObservedObject var impactDetector: ImpactDetector
    @ObservedObject var audioManager: AudioManager
    let categories: [SoundCategory]

    @State private var didSlap = false
    @State private var appeared = false
    @State private var iconScale: CGFloat = 1.0
    @State private var ringScale1: CGFloat = 0.5
    @State private var ringOpacity1: Double = 0
    @State private var ringScale2: CGFloat = 0.5
    @State private var ringOpacity2: Double = 0
    @State private var pulseAmount: CGFloat = 1.0
    @State private var slapCount = 0

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Impact zone
                ZStack {
                    // Impact rings (appear on slap)
                    Circle()
                        .stroke(Color.orange.opacity(ringOpacity1), lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale1)

                    Circle()
                        .stroke(Color.orange.opacity(ringOpacity2), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale2)

                    // Idle pulse
                    if !didSlap {
                        Circle()
                            .fill(Color.orange.opacity(0.06))
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseAmount)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    pulseAmount = 1.12
                                }
                            }
                    }

                    // Main icon
                    Image(systemName: didSlap ? "hand.thumbsup.fill" : "hand.raised.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(
                            didSlap
                            ? LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : onboardingAccent
                        )
                        .scaleEffect(iconScale)
                        .shadow(color: didSlap ? .green.opacity(0.3) : .orange.opacity(0.3), radius: 20)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .opacity(appeared ? 1 : 0)
                }
                .frame(height: 220)

                Spacer().frame(height: 32)

                // Status text
                Text(didSlap ? "Hissettim!" : "Telefona hafifçe vur")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                    .animation(.easeInOut, value: didSlap)

                Text(didSlap
                     ? "Mükemmel, her şey çalışıyor!"
                     : "Sensörünü test ediyoruz.")
                    .font(.body)
                    .foregroundColor(didSlap ? .green : .black.opacity(0.45))
                    .padding(.top, 8)
                    .animation(.easeInOut, value: didSlap)

                Spacer()

                OnboardingPageIndicator(currentPage: 2)
                    .padding(.bottom, 24)

                OnboardingButton(
                    title: didSlap ? "Harika, Devam Et" : "Atla",
                    isActive: didSlap,
                    action: onContinue
                )
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12).delay(0.15)) {
                appeared = true
            }
        }
        .onReceive(impactDetector.impactPublisher) { _ in
            slapCount += 1

            // Play demo sound on first slap
            if slapCount == 1,
               let goatCategory = categories.first(where: { $0.id == "goat" }),
               let firstPack = goatCategory.packs.first {
                audioManager.playChargerSound(from: firstPack, isTrial: true)
            }

            // Icon punch
            withAnimation(.interpolatingSpring(stiffness: 400, damping: 8)) {
                didSlap = true
                iconScale = 1.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 12)) {
                    iconScale = 1.0
                }
            }

            // Ring 1
            ringScale1 = 0.5
            ringOpacity1 = 0.8
            withAnimation(.easeOut(duration: 0.7)) {
                ringScale1 = 1.8
                ringOpacity1 = 0
            }

            // Ring 2 (delayed)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                ringScale2 = 0.5
                ringOpacity2 = 0.5
                withAnimation(.easeOut(duration: 0.6)) {
                    ringScale2 = 1.5
                    ringOpacity2 = 0
                }
            }
        }
    }
}
