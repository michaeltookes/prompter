import SwiftUI

/// SwiftUI view for selecting which decks the timer applies to.
///
/// Displays a list of decks with toggles. Reports the selected deck IDs
/// on Apply, or nil on Cancel.
struct DeckPickerPanelView: View {
    let decks: [Deck]
    let initialSelection: [UUID]
    let onComplete: ([UUID]?) -> Void

    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Select Decks for Timer")
                .font(Theme.titleSemibold)
                .foregroundColor(Theme.textPrimary)

            // Subtitle
            Text("Choose which decks should use the presentation timer:")
                .font(Theme.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Deck list
            if decks.isEmpty {
                Text("No decks available")
                    .font(Theme.note)
                    .foregroundColor(Theme.textSecondary)
                    .italic()
                    .padding(.vertical, 16)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(decks) { deck in
                            deckRow(deck)
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 200)
            }

            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onComplete(nil)
                }
                .keyboardShortcut(.cancelAction)
                .foregroundColor(Theme.textSecondary)

                Button("Apply") {
                    onComplete(Array(selectedIds))
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(selectedIds.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .onAppear {
            selectedIds = Set(initialSelection)
        }
    }

    // MARK: - Subviews

    private func deckRow(_ deck: Deck) -> some View {
        Button(action: { toggleDeck(deck.id) }) {
            HStack(spacing: 12) {
                Image(systemName: selectedIds.contains(deck.id) ? "checkmark.square.fill" : "square")
                    .font(.system(size: Theme.captionFontSize))
                    .foregroundColor(selectedIds.contains(deck.id) ? Theme.accent : Theme.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.title)
                        .font(Theme.footerMedium)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                        .font(Theme.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedIds.contains(deck.id) ? Theme.accent.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(deck.title), \(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
        .accessibilityValue(selectedIds.contains(deck.id) ? "Selected" : "Not selected")
        .accessibilityHint("Click to toggle selection")
    }

    // MARK: - Actions

    private func toggleDeck(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

#Preview {
    DeckPickerPanelView(
        decks: [
            Deck(title: "Demo Deck", cards: [Card(layout: .titleBullets)]),
            Deck(title: "Sales Pitch", cards: [Card(layout: .titleBullets), Card(layout: .imageTopNotes)])
        ],
        initialSelection: []
    ) { result in
        // preview callback
    }
}
