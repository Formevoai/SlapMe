import SwiftUI
import CoreMotion

struct SensorCheckView: View {
    var onContinue: () -> Void

    private let available = CMMotionManager().isAccelerometerAvailable
    @State private var appeared = false
    @State private var checkScale: CGFloat = 0.3
    @State private var ringPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // Status icon with modern ring
                ZStack {
                    // Pulse ring
                    Circle()
                        .stroke(
                            (available ? Color.green : Color.red).opacity(0.2),
                            lineWidth: 3
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(ringPulse)

                    // Background circle
                    Circle()
                        .fill(
                            (available ? Color.green : Color.red).opacity(0.08)
                        )
                        .frame(width: 130, height: 130)

                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundColor(available ? .green : .red)
                        .scaleEffect(checkScale)
                }
                .onAppear {
                    withAnimation(.interpolatingSpring(stiffness: 120, damping: 10).delay(0.2)) {
                        checkScale = 1.0
                    }
                    guard available else { return }
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        ringPulse = 1.12
                    }
                }
                .padding(.bottom, 36)

                // Status text
                Text(available ? L("sensor_ready") : L("sensor_not_found"))
                    .font(.title.bold())
                    .foregroundColor(.black)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Text(available
                     ? L("sensor_active_description")
                     : L("sensor_not_supported"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.45))
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                Spacer()

                OnboardingPageIndicator(currentPage: 1)
                    .padding(.bottom, 24)

                OnboardingButton(title: L("button_continue"), isActive: available, action: onContinue)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 100, damping: 12).delay(0.3)) {
                appeared = true
            }
        }
    }
}
