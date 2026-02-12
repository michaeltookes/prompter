import SwiftUI

/// Renders the 2x2 Grid + Caption layout in the overlay.
struct Grid2x2CaptionRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 2x2 Grid of images
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    gridImage(at: index)
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius - 4))
                }
            }

            // Caption
            if let caption = card.caption, !caption.isEmpty {
                Text(caption)
                    .font(.system(size: Theme.captionFontSize * fontScale, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func gridImage(at index: Int) -> some View {
        if card.images.count > index,
           let assetRef = card.images[index] {
            OverlayImageView(assetRef: assetRef)
                .accessibilityLabel("Grid image \(index + 1)")
        } else {
            RoundedRectangle(cornerRadius: Theme.imageCornerRadius - 4)
                .fill(Theme.dropZoneBackground)
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                        .accessibilityHidden(true)
                )
                .accessibilityLabel("Empty image slot \(index + 1)")
        }
    }
}

#Preview {
    Grid2x2CaptionRenderer(
        card: Card(
            layout: .grid2x2Caption,
            caption: "Four-step onboarding process"
        ),
        fontScale: 1.0
    )
    .padding()
    .frame(width: 350)
    .background(Theme.surfaceBackground)
}
