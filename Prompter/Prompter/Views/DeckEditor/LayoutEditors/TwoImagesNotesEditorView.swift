import SwiftUI

/// Editor for the Two Images + Notes layout.
///
/// Fields:
/// - Image 1: Left image drop zone
/// - Image 2: Right image drop zone
/// - Notes: Multi-line text field
struct TwoImagesNotesEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Images section
            VStack(alignment: .leading, spacing: 8) {
                Text("Images")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        ImageDropZone(
                            assetRef: imageBinding(at: 0),
                            placeholder: "Image 1"
                        )
                        .frame(height: 150)

                        Text("Left")
                            .font(.caption)
                            .foregroundColor(Theme.editorTextSecondary)
                    }

                    VStack(spacing: 4) {
                        ImageDropZone(
                            assetRef: imageBinding(at: 1),
                            placeholder: "Image 2"
                        )
                        .frame(height: 150)

                        Text("Right")
                            .font(.caption)
                            .foregroundColor(Theme.editorTextSecondary)
                    }
                }
            }

            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                TextEditor(text: notesBinding)
                    .font(.body)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.editorBorder, lineWidth: 1)
                    )
            }

            Spacer()
        }
        .frame(maxWidth: 600, alignment: .leading)
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

                // Ensure array is large enough
                while images.count <= index {
                    images.append(nil)
                }

                images[index] = newValue
                card.images = images
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { card.notes ?? "" },
            set: { card.notes = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    TwoImagesNotesEditorView(card: .constant(Card(
        layout: .twoImagesNotes,
        notes: "Compare the before and after."
    )))
    .padding()
    .frame(width: 500, height: 500)
}
