import SwiftUI

/// Renders the Two Images + Notes layout in the overlay.
struct TwoImagesNotesRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Two images side by side
            HStack(spacing: 12) {
                // Image 1
                if card.images.count > 0, let assetRef = card.images[0] {
                    OverlayImageView(assetRef: assetRef)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius))
                } else {
                    imagePlaceholder
                }

                // Image 2
                if card.images.count > 1, let assetRef = card.images[1] {
                    OverlayImageView(assetRef: assetRef)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius))
                } else {
                    imagePlaceholder
                }
            }

            // Notes
            if let notes = card.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: Theme.notesFontSize * fontScale))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: Theme.imageCornerRadius)
            .fill(Theme.dropZoneBackground)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.textSecondary)
            )
    }
}

#Preview {
    TwoImagesNotesRenderer(
        card: Card(
            layout: .twoImagesNotes,
            notes: "Compare the before (left) and after (right) states."
        ),
        fontScale: 1.0
    )
    .padding()
    .frame(width: 400)
    .background(Theme.surfaceBackground)
}
