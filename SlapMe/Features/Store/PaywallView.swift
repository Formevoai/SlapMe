import SwiftUI

struct PaywallView: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var glowPulse = false
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background — clean white
            Color.white
                .ignoresSafeArea()

            // Subtle radial glow behind crown
            RadialGradient(
                colors: [Color.orange.opacity(0.08), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .offset(y: -120)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.bold())
                            .foregroundColor(.black.opacity(0.4))
                            .padding(10)
                            .background(.black.opacity(0.05), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Crown + hand icon
                ZStack {
                    // Glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 110, height: 110)
                        .scaleEffect(glowPulse ? 1.15 : 1.0)
                        .opacity(glowPulse ? 0 : 0.6)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.96), Color(white: 0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.06), lineWidth: 1)
                        )

                    VStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .padding(.bottom, 20)
                .scaleEffect(appear ? 1.0 : 0.5)
                .opacity(appear ? 1 : 0)

                // Title
                HStack(spacing: 6) {
                    Text("SlapMe")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                    Text("PRO")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 10)

                Text(L("paywall_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.4))
                    .padding(.top, 6)

                Spacer()

                // Features
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(
                        icon: "hand.raised.fill", color: .pink,
                        text: L("feature_all_premium_sounds"))
                    featureRow(
                        icon: "person.3.fill", color: .purple, text: L("feature_all_characters"))
                    featureRow(icon: "bolt.fill", color: .green, text: L("feature_charger_sounds"))
                    featureRow(
                        icon: "sparkles", color: .yellow, text: L("feature_all_future_updates"))
                    featureRow(icon: "infinity", color: .cyan, text: L("feature_unlimited_usage"))
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)

                // Price badge
                Text(storeManager.priceText)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.bottom, 4)

                Text(L("one_time_payment_label"))
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.3))
                    .padding(.bottom, 20)

                // Buy button
                Button {
                    Task {
                        await storeManager.purchase()
                        if storeManager.isPremium { dismiss() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if storeManager.isPurchasing {
                            ProgressView()
                                .tint(.black)
                        }
                        Image(systemName: "crown.fill")
                            .font(.subheadline.bold())
                        Text(
                            storeManager.isPurchasing
                                ? L("purchasing_in_progress") : L("upgrade_to_pro")
                        )
                        .font(.headline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .orange.opacity(0.4), radius: 16, y: 6)
                }
                .disabled(storeManager.isPurchasing)
                .padding(.horizontal, 32)
                .scaleEffect(appear ? 1.0 : 0.9)

                // Restore
                Button {
                    Task {
                        await storeManager.restore()
                        if storeManager.isPremium { dismiss() }
                    }
                } label: {
                    Text(L("restore_purchases"))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.3))
                }
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                glowPulse = true
            }
        }
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))
        }
    }
}
