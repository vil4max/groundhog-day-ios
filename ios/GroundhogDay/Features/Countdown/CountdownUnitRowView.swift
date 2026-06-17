import SwiftUI

struct CountdownUnitRowView: View {
    enum Style {
        case carousel
        case list
    }

    @Environment(\.countdownTileMetrics) private var metrics

    let unit: CountdownUnit
    let value: Int
    let isSettled: Bool
    let isSpinning: Bool
    let isMuted: Bool
    let reduceMotion: Bool
    var style: Style = .list
    var containerWidth: CGFloat?
    var screenHeight: CGFloat?

    var body: some View {
        VStack(spacing: style == .carousel ? 0 : 8) {
            HStack(spacing: rowMetrics.digitSpacing) {
                ForEach(Array(displayDigits.enumerated()), id: \.offset) { _, digit in
                    FlipDigitView(
                        digit: digit,
                        isSpinning: isSpinning,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .environment(\.countdownTileMetrics, rowMetrics)
            .frame(maxWidth: .infinity, alignment: .center)

            if style != .carousel {
                Text(String(localized: String.LocalizationValue(unit.localizationKey)))
                    .font(metrics.unitFont)
                    .foregroundStyle(isMuted ? FlipClockTheme.labelMuted : FlipClockTheme.label)
            }
        }
        .opacity(isMuted ? 0.35 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var displayDigits: [Int] {
        let text = String(max(0, value))
        if text.isEmpty {
            return [0]
        }
        return text.compactMap { Int(String($0)) }
    }

    private var rowMetrics: CountdownTileMetrics {
        if style == .carousel, let containerWidth, let screenHeight {
            return FlipClockTheme.tileMetrics(
                forScreenHeight: screenHeight,
                containerWidth: containerWidth,
                digitCount: max(2, displayDigits.count)
            )
        }
        return metrics
    }

    private var accessibilityText: String {
        let unitName = String(localized: String.LocalizationValue(unit.localizationKey))
        return "\(value) \(unitName)"
    }
}
