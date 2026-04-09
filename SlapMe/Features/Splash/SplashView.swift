import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var glowRadius: CGFloat = 10
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var exitOpacity: Double = 1

    var body: some View {
        ZStack {
            // MARK: Background
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.04, blue: 0.20),
                    Color(red: 0.04, green: 0.02, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: Ambient glow blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -60, y: -80)

                Circle()
                    .fill(Color(red: 1, green: 0.55, blue: 0.1).opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.55)
            }
            .ignoresSafeArea()

            // MARK: Sparkle particles
            SparkleField()

            // MARK: Content
            VStack(spacing: 28) {
                // Logo
                ZStack {
                    // Pulsing glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.45), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: glowRadius)

                    // Icon with rounded corners
                    Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .shadow(color: Color.purple.opacity(0.6), radius: 24, y: 8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Text group
                VStack(spacing: 8) {
                    Text("SlapMe")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 1.0, green: 0.88, blue: 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.7), radius: 12)

                    Text("Slap. Play. Repeat.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundColor(.white.opacity(0.45))
                        .opacity(taglineOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .opacity(exitOpacity)
        .onAppear {
            // Logo pops in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            // Glow pulse
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(0.3)) {
                glowRadius = 30
            }
            // Title slides up
            withAnimation(.easeOut(duration: 0.45).delay(0.4)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            // Tagline fades
            withAnimation(.easeOut(duration: 0.4).delay(0.65)) {
                taglineOpacity = 1.0
            }
            // Exit after 1.9s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                withAnimation(.easeIn(duration: 0.35)) {
                    exitOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFinished()
                }
            }
        }
    }
}

// MARK: - Sparkle Field

private struct SparkleField: View {
    // (xFraction, yFraction, size, initialDelay)
    private let particles: [(CGFloat, CGFloat, CGFloat, Double)] = [
        (0.08, 0.12, 10, 0.0),
        (0.88, 0.10, 7, 0.3),
        (0.15, 0.78, 8, 0.5),
        (0.82, 0.70, 11, 0.1),
        (0.50, 0.06, 6, 0.7),
        (0.30, 0.88, 9, 0.2),
        (0.70, 0.45, 7, 0.4),
        (0.92, 0.40, 6, 0.6),
        (0.45, 0.92, 10, 0.8),
        (0.05, 0.50, 7, 0.9),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(particles.enumerated()), id: \.offset) { index, p in
                SparkleParticle(size: p.2, delay: p.3)
                    .position(
                        x: geo.size.width * p.0,
                        y: geo.size.height * p.1
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct SparkleParticle: View {
    let size: CGFloat
    let delay: Double

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.6

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 1, green: 0.9, blue: 0.4), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.8...1.3))
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    opacity = Double.random(in: 0.5...0.9)
                    scale = Double.random(in: 0.9...1.3)
                }
            }
    }
}
