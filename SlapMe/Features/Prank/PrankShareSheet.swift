import SwiftUI
import UIKit

// MARK: - UIActivityViewController Wrapper

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Prank Share Sheet

struct PrankShareSheet: View {
    let pack: SoundPack
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var selectedDelay = 5
    @State private var showActivitySheet = false

    private let delayOptions = [0, 3, 5, 10]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Pack header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Text("👋")
                            .font(.system(size: 28))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pack.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text(L("prank_sheet_title"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                Divider()
                    .padding(.bottom, 24)

                // Delay picker
                VStack(alignment: .leading, spacing: 14) {
                    Text(L("prank_delay_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(delayOptions, id: \.self) { d in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { selectedDelay = d }
                                } label: {
                                    Text(delayLabel(d))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(selectedDelay == d ? .white : .primary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 11)
                                        .background(
                                            selectedDelay == d
                                                ? Color.pink : Color(.systemGray6),
                                            in: RoundedRectangle(cornerRadius: 14)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()

                // Share button
                Button {
                    showActivitySheet = true
                } label: {
                    Label(L("prank_send_btn"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.pink, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle(L("prank_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("custom_cancel_btn")) { dismiss() }
                }
            }
            .sheet(isPresented: $showActivitySheet) {
                ActivityView(activityItems: [L("prank_share_msg"), prankURL()])
            }
        }
    }

    private func delayLabel(_ d: Int) -> String {
        switch d {
        case 0: return L("prank_delay_now")
        case 3: return L("prank_delay_3s")
        case 5: return L("prank_delay_5s")
        case 10: return L("prank_delay_10s")
        default: return "\(d)s"
        }
    }

    private func prankURL() -> URL {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "prank.formevo.app"
        comps.path = "/prank/"
        comps.queryItems = [
            URLQueryItem(name: "pack", value: pack.id),
            URLQueryItem(name: "delay", value: "\(selectedDelay)"),
        ]
        return comps.url ?? URL(string: "https://prank.formevo.app/prank/")!
    }
}
