import SwiftUI

/// Renders the Image + Notes layout in the overlay.
struct ImageTopNotesRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image
            if let firstImage = card.images.first,
               let assetRef = firstImage {
                OverlayImageView(assetRef: assetRef)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.imageCornerRadius))
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
}

/// Image view optimized for overlay display
struct OverlayImageView: View {
    let assetRef: AssetRef

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .accessibilityLabel("Slide image")
            } else {
                Rectangle()
                    .fill(Theme.dropZoneBackground)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
                    .accessibilityLabel("Loading image")
            }
        }
        .onAppear { loadImage() }
        .onChange(of: assetRef.id) { _, _ in loadImage() }
    }

    private func loadImage() {
        if let nsImage = AssetManager.shared.loadImage(for: assetRef) {
            self.image = nsImage
        }
    }
}

#Preview {
    ImageTopNotesRenderer(
        card: Card(
            layout: .imageTopNotes,
            notes: "This screenshot shows the main dashboard with all key metrics visible."
        ),
        fontScale: 1.0
    )
    .padding()
    .background(Theme.surfaceBackground)
}
