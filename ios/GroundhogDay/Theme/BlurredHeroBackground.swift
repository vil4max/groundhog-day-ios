import SwiftUI

struct BlurredHeroBackground: View {
    let imageName: String
    var imageHeight: CGFloat?

    var body: some View {
        ZStack(alignment: .top) {
            heroImage
                .blur(radius: 10, opaque: true)
                .clipped()
            LinearGradient(
                colors: [
                    FlipClockTheme.accent.opacity(0.12),
                    FlipClockTheme.surface.opacity(0.45),
                    FlipClockTheme.surface.opacity(0.94),
                    FlipClockTheme.surface
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .background(FlipClockTheme.surface)
    }

    @ViewBuilder
    private var heroImage: some View {
        if let imageHeight {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: imageHeight)
                .frame(maxWidth: .infinity)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
