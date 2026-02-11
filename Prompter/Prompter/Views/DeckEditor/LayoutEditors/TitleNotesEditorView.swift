import SwiftUI

/// Editor for the Title + Notes layout.
///
/// Fields:
/// - Title: Single line text field
/// - Notes: Multi-line text field
struct TitleNotesEditorView: View {
    @Binding var card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(Theme.textSecondary)

                TextField("Enter title...", text: titleBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
            }

            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(Theme.textSecondary)

                TextEditor(text: notesBinding)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.divider, lineWidth: 1)
                    )
            }

            Spacer()
        }
        .frame(maxWidth: 600, alignment: .leading)
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { card.title ?? "" },
            set: { card.title = $0.isEmpty ? nil : $0 }
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
    TitleNotesEditorView(card: .constant(Card(
        layout: .titleNotes,
        title: "Key Points",
        notes: "These are detailed notes about the topic being discussed."
    )))
    .padding()
    .frame(width: 500, height: 400)
}
