import SwiftUI

struct DisclaimerView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    disclaimerSection(
                        icon: "exclamationmark.triangle.fill",
                        title: L("disclaimer_title_safety"),
                        text: L("disclaimer_text_safety"),
                        color: .orange
                    )

                    disclaimerSection(
                        icon: "iphone.slash",
                        title: L("disclaimer_title_device"),
                        text: L("disclaimer_text_device"),
                        color: .red
                    )

                    disclaimerSection(
                        icon: "figure.wave",
                        title: L("disclaimer_title_usage"),
                        text: L("disclaimer_text_usage"),
                        color: .blue
                    )

                    disclaimerSection(
                        icon: "person.2.fill",
                        title: L("disclaimer_title_consent"),
                        text: L("disclaimer_text_consent"),
                        color: .purple
                    )

                    disclaimerSection(
                        icon: "hand.raised.fill",
                        title: L("disclaimer_title_liability"),
                        text: L("disclaimer_text_liability"),
                        color: .gray
                    )
                }

                Text(L("disclaimer_footer"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(L("settings_disclaimer"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func disclaimerSection(icon: String, title: String, text: String, color: Color)
        -> some View
    {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}
