import SwiftUI

/// Sidebar showing the list of cards in the current deck.
///
/// Features:
/// - Card thumbnails with layout icons
/// - Drag-to-reorder cards
/// - Add, duplicate, delete cards
/// - Selection state
struct CardListSidebar: View {
    @EnvironmentObject var appState: AppState

    /// Currently selected card index
    @Binding var selectedIndex: Int

    /// Card being dragged for reordering
    @State private var draggedCard: Card?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader

            Divider()

            // Card list
            if let deck = appState.currentDeck, !deck.cards.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(deck.cards.enumerated()), id: \.element.id) { index, card in
                                CardListItem(
                                    card: card,
                                    index: index,
                                    isSelected: index == selectedIndex,
                                    onSelect: { selectedIndex = index },
                                    onDelete: { deleteCard(at: index) },
                                    onDuplicate: { duplicateCard(at: index) }
                                )
                                .id(card.id)
                                .onDrag {
                                    draggedCard = card
                                    return NSItemProvider(object: card.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: CardDropDelegate(
                                    item: card,
                                    items: deck.cards,
                                    draggedItem: $draggedCard,
                                    onReorder: { from, to in
                                        reorderCard(from: from, to: to)
                                    }
                                ))
                            }
                        }
                        .padding(12)
                    }
                    .onChange(of: selectedIndex) { _, newIndex in
                        if let deck = appState.currentDeck,
                           newIndex >= 0 && newIndex < deck.cards.count {
                            withAnimation {
                                proxy.scrollTo(deck.cards[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            } else {
                // Empty state
                emptyState
            }
        }
        .frame(width: 220)
        .background(Theme.sidebarBackground)
    }

    // MARK: - Subviews

    private var sidebarHeader: some View {
        HStack {
            Text("Cards")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            // Add card menu
            Menu {
                ForEach(LayoutType.allCases) { layout in
                    Button(action: { addCard(layout: layout) }) {
                        Label(layout.displayName, systemImage: layout.iconName)
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.textSecondary)

            Text("No Cards")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)

            Text("Click + to add a card")
                .font(.caption)
                .foregroundColor(Theme.textSecondary.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func addCard(layout: LayoutType) {
        let newCard = Card(layout: layout)
        appState.addCard(newCard)

        // Select the new card
        if let deck = appState.currentDeck {
            selectedIndex = deck.cards.count - 1
        }
    }

    private func deleteCard(at index: Int) {
        guard let deck = appState.currentDeck, deck.cards.count > 0 else { return }

        appState.deleteCard(at: index)

        // Adjust selection
        if selectedIndex >= deck.cards.count - 1 {
            selectedIndex = max(0, deck.cards.count - 2)
        }
    }

    private func duplicateCard(at index: Int) {
        guard let deck = appState.currentDeck,
              index >= 0 && index < deck.cards.count else { return }

        let original = deck.cards[index]
        let duplicate = Card(
            layout: original.layout,
            title: original.title,
            notes: original.notes,
            bullets: original.bullets,
            caption: original.caption,
            imageSlots: original.imageSlots
        )

        appState.insertCard(duplicate, at: index + 1)
        selectedIndex = index + 1
    }

    private func reorderCard(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        appState.moveCard(from: sourceIndex, to: destinationIndex)

        // Update selection to follow the moved card
        selectedIndex = destinationIndex
    }
}

// MARK: - Card List Item

struct CardListItem: View {
    let card: Card
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Layout icon
                Image(systemName: card.layout.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
                    .frame(width: 24)

                // Card info
                VStack(alignment: .leading, spacing: 2) {
                    Text(cardTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text(card.layout.displayName)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // Card number
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.accent.opacity(0.2) : (isHovered ? Color.white.opacity(0.05) : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "square.on.square")
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var cardTitle: String {
        if let title = card.title, !title.isEmpty {
            return title
        }
        if let notes = card.notes, !notes.isEmpty {
            return String(notes.prefix(30))
        }
        if let bullets = card.bullets, let first = bullets.first {
            return String(first.prefix(30))
        }
        return "Card \(index + 1)"
    }
}

// MARK: - Drop Delegate

struct CardDropDelegate: DropDelegate {
    let item: Card
    let items: [Card]
    @Binding var draggedItem: Card?
    let onReorder: (Int, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        onReorder(fromIndex, toIndex)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
