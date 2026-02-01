import SwiftUI

/// Renders a card using the appropriate layout renderer.
///
/// This view delegates to the specific layout renderer based on the card's layout type.
struct OverlayCardRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        switch card.layout {
        case .titleBullets:
            TitleBulletsRenderer(card: card, fontScale: fontScale)
        case .imageTopNotes:
            ImageTopNotesRenderer(card: card, fontScale: fontScale)
        case .twoImagesNotes:
            TwoImagesNotesRenderer(card: card, fontScale: fontScale)
        case .grid2x2Caption:
            Grid2x2CaptionRenderer(card: card, fontScale: fontScale)
        case .fullBleedBullets:
            FullBleedBulletsRenderer(card: card, fontScale: fontScale)
        }
    }
}

#Preview("Title + Bullets") {
    OverlayCardRenderer(
        card: Card(
            layout: .titleBullets,
            title: "Demo Highlights",
            bullets: ["Feature A", "Feature B", "Feature C"]
        ),
        fontScale: 1.0
    )
    .padding()
    .background(Theme.surfaceBackground)
}

#Preview("Image + Notes") {
    OverlayCardRenderer(
        card: Card(
            layout: .imageTopNotes,
            notes: "This shows the main dashboard"
        ),
        fontScale: 1.0
    )
    .padding()
    .background(Theme.surfaceBackground)
}
