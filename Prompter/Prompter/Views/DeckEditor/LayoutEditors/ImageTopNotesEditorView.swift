import SwiftUI

/// Editor for the Image + Notes layout.
///
/// Fields:
/// - Image: Single drop zone for one image
/// - Notes: Multi-line text field
struct ImageTopNotesEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Image section
            VStack(alignment: .leading, spacing: 8) {
                Text("Image")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                ImageDropZone(
                    assetRef: imageBinding(at: 0),
                    placeholder: "Drop image here"
                )
                .frame(height: 200)
            }

            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(Theme.editorTextSecondary)

                TextEditor(text: notesBinding)
                    .font(.body)
                    .frame(minHeight: 120)
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
    ImageTopNotesEditorView(card: .constant(Card(
        layout: .imageTopNotes,
        notes: "These are my notes about the image above."
    )))
    .padding()
    .frame(width: 500, height: 500)
}
