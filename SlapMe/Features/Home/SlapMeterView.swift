import SwiftUI

struct SlapMeterView: View {
    let intensity: Double
    @Environment(\.colorScheme) private var colorScheme

    private var trackColor: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06)
    }
    private var labelColor: Color {
        colorScheme == .dark ? .white.opacity(0.45) : .black.opacity(0.35)
    }
    private var tickColor: Color {
        colorScheme == .dark ? .white.opacity(0.15) : .black.opacity(0.1)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(L("slap_meter_label"))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(labelColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(trackColor)
                        .frame(height: 7)

                    // Glow fill
                    Capsule()
                        .fill(meterGradient)
                        .frame(width: max(0, geo.size.width * intensity), height: 7)
                        .shadow(color: meterColor.opacity(0.9), radius: 8)
                        .shadow(color: meterColor.opacity(0.5), radius: 3)
                        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: intensity)

                    // Tick marks
                    HStack(spacing: 0) {
                        ForEach(0..<4) { i in
                            Spacer()
                            Rectangle()
                                .fill(tickColor)
                                .frame(width: 1, height: 12)
                        }
                        Spacer()
                    }
                    .frame(height: 12)
                    .offset(y: -2.5)
                }
            }
            .frame(height: 12)
        }
    }

    private var meterColor: Color {
        switch intensity {
        case 0.0 ..< 0.4:  return Color(red: 0.2, green: 1.0, blue: 0.5)
        case 0.4 ..< 0.75: return Color(red: 1.0, green: 0.65, blue: 0.1)
        default:            return Color(red: 1.0, green: 0.25, blue: 0.35)
        }
    }

    private var meterGradient: LinearGradient {
        LinearGradient(
            colors: [meterColor.opacity(0.6), meterColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
