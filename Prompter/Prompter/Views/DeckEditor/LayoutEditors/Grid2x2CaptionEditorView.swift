import SwiftUI

/// Editor for the 2x2 Grid + Caption layout.
///
/// Fields:
/// - 4 Images: Arranged in a 2x2 grid
/// - Caption: Single line text field
struct Grid2x2CaptionEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Images grid section
            VStack(alignment: .leading, spacing: 8) {
                Text("Images (2×2 Grid)")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        VStack(spacing: 4) {
                            ImageDropZone(
                                assetRef: imageBinding(at: index),
                                placeholder: "Image \(index + 1)"
                            )
                            .frame(height: 120)

                            Text(gridPosition(for: index))
                                .font(.caption)
                                .foregroundColor(Theme.editorTextSecondary)
                        }
                    }
                }
            }

            // Caption section
            VStack(alignment: .leading, spacing: 8) {
                Text("Caption")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                TextField("Enter caption...", text: captionBinding)
                    .textFieldStyle(.roundedBorder)
            }

            Spacer()
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    // MARK: - Helpers

    private func gridPosition(for index: Int) -> String {
        switch index {
        case 0: return "Top Left"
        case 1: return "Top Right"
        case 2: return "Bottom Left"
        case 3: return "Bottom Right"
        default: return ""
        }
    }

    // MARK: - Bindings

    private func imageBinding(at index: Int) -> Binding<AssetRef?> {
        Binding(
            get: {
                guard index < card.images.count else { return nil }
                return card.images[index]
            },
            set: { newValue in
                var images = card.images

                // Ensure array is large enough (4 slots for 2x2 grid)
                while images.count < 4 {
                    images.append(nil)
                }

                images[index] = newValue
                card.images = images
            }
        )
    }

    private var captionBinding: Binding<String> {
        Binding(
            get: { card.caption ?? "" },
            set: { card.caption = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    Grid2x2CaptionEditorView(card: .constant(Card(
        layout: .grid2x2Caption,
        caption: "Four-step process flow"
    )))
    .padding()
    .frame(width: 500, height: 500)
}
