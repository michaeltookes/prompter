import SwiftUI

/// Renders the Full Image + 3 Bullets layout in the overlay.
struct FullBleedBulletsRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Full-bleed image
            if let firstImage = card.images.first,
               let assetRef = firstImage {
                OverlayImageView(assetRef: assetRef)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius))
            } else {
                // Placeholder for missing image
                RoundedRectangle(cornerRadius: Theme.imageCornerRadius)
                    .fill(Theme.dropZoneBackground)
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.textSecondary.opacity(0.5))
                    )
            }

            // 3 Bullets
            if let bullets = card.bullets {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(bullets.prefix(3).enumerated()), id: \.offset) { index, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            // Numbered bullet
                            Text("\(index + 1)")
                                .font(.system(size: 14 * fontScale, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .frame(width: 22, height: 22)
                                .background(Theme.accent.opacity(0.2))
                                .clipShape(Circle())

                            Text(bullet)
                                .font(.system(size: Theme.notesFontSize * fontScale))
                                .foregroundColor(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FullBleedBulletsRenderer(
        card: Card(
            layout: .fullBleedBullets,
            bullets: [
                "Key benefit number one",
                "Important feature to highlight",
                "Final takeaway point"
            ]
        ),
        fontScale: 1.0
    )
    .padding()
    .frame(width: 350)
    .background(Theme.surfaceBackground)
}
