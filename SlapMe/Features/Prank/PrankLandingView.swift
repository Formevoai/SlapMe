import SwiftUI

struct PrankLandingView: View {
    let pack: SoundPack
    let delay: Int
    @ObservedObject var audioManager: AudioManager
    var onDismiss: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var progress: Double = 0
    @State private var progressPct: Int = 0
    @State private var showBoom = false

    var body: some View {
        ZStack {
            if showBoom {
                boomView
                    .transition(.opacity)
            } else {
                loadingView
            }
        }
        .ignoresSafeArea()
        .onAppear { startProgress() }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 108, height: 108)
                        Image(systemName: "arrow.down.to.line.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }

                    VStack(spacing: 8) {
                        Text(L("prank_loading_title"))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L("prank_loading_subtitle"))
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                // Progress bar
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 10)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.9), .white.opacity(0.55)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * progress), height: 10)
                                .animation(.easeInOut(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 10)

                    Text("\(progressPct)%")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 52)

                Spacer()
                Spacer()
            }
        }
    }

    // MARK: - Boom View

    private var boomView: some View {
        ZStack {
            Color(red: 0.88, green: 0.12, blue: 0.18).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("👋")
                    .font(.system(size: 96))
                    .scaleEffect(showBoom ? 1.0 : 0.2)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.45), value: showBoom)

                Text(L("prank_got_you"))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("SlapMe")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 8)
            }
        }
        .onTapGesture { onDismiss() }
    }

    // MARK: - Logic

    private func startProgress() {
        let total = Double(max(delay, 2))

        // Stage 1: 0 → 76% easeIn
        withAnimation(.easeIn(duration: total * 0.60)) { progress = 0.76 }

        // Stage 2: 76% → 93%
        DispatchQueue.main.asyncAfter(deadline: .now() + total * 0.62) {
            withAnimation(.linear(duration: total * 0.22)) { progress = 0.93 }
        }

        // Stage 3: 93% → 100%
        DispatchQueue.main.asyncAfter(deadline: .now() + total - 0.55) {
            withAnimation(.easeInOut(duration: 0.45)) { progress = 1.0 }
        }

        // Text ticker
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            progressPct = min(Int(progress * 100), 99)
            if showBoom { timer.invalidate() }
        }

        // BOOM
        DispatchQueue.main.asyncAfter(deadline: .now() + total) { boom() }
    }

    private func boom() {
        progressPct = 100
        audioManager.playChargerSound(from: pack, isTrial: false)
        withAnimation(.spring(response: 0.3)) { showBoom = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { onDismiss() }
    }
}
