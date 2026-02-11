import SwiftUI

/// Renders the Title + Notes layout in the overlay.
struct TitleNotesRenderer: View {
    let card: Card
    let fontScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            if let title = card.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: Theme.titleFontSize * fontScale, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
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

#Preview {
    TitleNotesRenderer(
        card: Card(
            layout: .titleNotes,
            title: "Key Points",
            notes: "These are detailed notes about the topic being discussed.\n\nYou can include multiple paragraphs of context here."
        ),
        fontScale: 1.0
    )
    .padding()
    .background(Theme.surfaceBackground)
}
