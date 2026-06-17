import SwiftUI
import UIKit

enum FlipClockTheme {
    static let background = adaptiveColor(
        light: rgb(0.957, 0.953, 0.945),
        dark: rgb(0.098, 0.098, 0.098)
    )

    static let surface = adaptiveColor(
        light: rgb(1.000, 0.996, 0.988),
        dark: rgb(0.141, 0.141, 0.141)
    )

    static let displayPanel = adaptiveColor(
        light: rgb(0.988, 0.984, 0.976),
        dark: rgb(0.165, 0.165, 0.165)
    )

    static let tileBorder = adaptiveColor(
        light: rgb(0.898, 0.894, 0.886),
        dark: rgb(0.220, 0.220, 0.220)
    )

    static let tileSplit = adaptiveColor(
        light: rgb(0.878, 0.875, 0.867),
        dark: rgb(0.090, 0.090, 0.090)
    )

    static let digit = adaptiveColor(
        light: rgb(0.200, 0.200, 0.200),
        dark: rgb(0.769, 0.749, 0.725)
    )

    static let primaryText = adaptiveColor(
        light: rgb(0.200, 0.200, 0.200),
        dark: rgb(0.820, 0.800, 0.776)
    )

    static let label = adaptiveColor(
        light: rgb(0.541, 0.529, 0.510),
        dark: rgb(0.604, 0.588, 0.569)
    )

    static let labelMuted = adaptiveColor(
        light: rgb(0.710, 0.698, 0.678),
        dark: rgb(0.431, 0.416, 0.396)
    )

    static let eventDate = adaptiveColor(
        light: rgb(0.431, 0.420, 0.400),
        dark: rgb(0.659, 0.643, 0.624)
    )

    static let accent = adaptiveColor(
        light: rgb(0.631, 0.475, 0.333),
        dark: rgb(0.788, 0.584, 0.384)
    )

    static let onAccent = adaptiveColor(
        light: rgb(0.992, 0.976, 0.953),
        dark: rgb(0.118, 0.075, 0.039)
    )

    static let digitFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let unitFont = Font.caption
    static let contextFont = Font.subheadline
    static let quoteBodyFont = Font.system(.title3, design: .serif).italic()
    static let quoteTitleFont = Font.system(.title2, design: .serif).weight(.bold).italic()
    static let eventBannerCaptionFont = Font.caption.weight(.semibold)
    static let eventBannerDateFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let eventBannerTimeFont = Font.subheadline.weight(.medium)
    static let eventBannerLabelFont = Font.subheadline.weight(.semibold)
    static let tileSize = CGSize(width: 36, height: 40)
    static let tileCornerRadius: CGFloat = 6
    static let rowSpacing: CGFloat = 20

    static func tileMetrics(forContainerWidth width: CGFloat) -> CountdownTileMetrics {
        let contentWidth = max(width, 320)
        let digitGap: CGFloat = 12
        let tileWidth = min(72, max(50, floor((contentWidth * 0.42 - digitGap) / 2)))
        let tileHeight = tileWidth * 1.15
        let fontSize = tileWidth * 0.68
        return CountdownTileMetrics(
            tileSize: CGSize(width: tileWidth, height: tileHeight),
            digitFont: .system(size: fontSize, weight: .bold, design: .rounded),
            cornerRadius: max(8, tileWidth * 0.13),
            digitSpacing: digitGap,
            rowSpacing: max(12, tileHeight * 0.2),
            unitFont: .footnote
        )
    }

    static func tileMetrics(
        forScreenHeight screenHeight: CGFloat,
        containerWidth width: CGFloat,
        digitCount: Int = 2
    ) -> CountdownTileMetrics {
        let count = max(2, digitCount)
        let rowWidth = width * 0.9
        let digitGap: CGFloat = count <= 2 ? 18 : (count == 3 ? 14 : 10)
        let twoDigitTileWidth = min(screenHeight * 0.30, 280) * 0.44
        let fittedTileWidth = (rowWidth - digitGap * CGFloat(count - 1)) / CGFloat(count)
        let tileWidth = count <= 2 ? twoDigitTileWidth : fittedTileWidth
        let tileHeight = min(screenHeight * 0.30, tileWidth * 2.35)
        let fontSize = tileHeight * (count <= 2 ? 0.54 : 0.48)
        return CountdownTileMetrics(
            tileSize: CGSize(width: tileWidth, height: tileHeight),
            digitFont: .system(size: fontSize, weight: .bold, design: .rounded),
            cornerRadius: max(12, tileWidth * 0.12),
            digitSpacing: digitGap,
            rowSpacing: 16,
            unitFont: .title2
        )
    }

    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct CountdownTileMetrics {
    let tileSize: CGSize
    let digitFont: Font
    let cornerRadius: CGFloat
    let digitSpacing: CGFloat
    let rowSpacing: CGFloat
    let unitFont: Font

    static let `default` = FlipClockTheme.tileMetrics(forContainerWidth: 390)
}

private struct CountdownTileMetricsKey: EnvironmentKey {
    static let defaultValue = CountdownTileMetrics.default
}

extension EnvironmentValues {
    var countdownTileMetrics: CountdownTileMetrics {
        get { self[CountdownTileMetricsKey.self] }
        set { self[CountdownTileMetricsKey.self] = newValue }
    }
}
