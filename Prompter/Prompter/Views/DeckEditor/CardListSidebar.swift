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

    /// Whether to show the new deck dialog
    @State private var showNewDeckDialog = false

    /// Whether to show the delete deck confirmation
    @State private var showDeleteConfirmation = false

    /// New deck title input
    @State private var newDeckTitle = ""

    /// Whether the deck list is expanded
    @State private var isDeckListExpanded = false

    /// Whether the deck title is being edited inline
    @State private var isEditingDeckTitle = false

    /// Inline deck title edit value
    @State private var editingDeckTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            // Deck picker section
            deckPickerSection

            Rectangle().fill(Theme.editorBorder).frame(height: 1)

            // Header
            sidebarHeader

            Rectangle().fill(Theme.editorBorder).frame(height: 1)

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
                                    onDuplicate: { duplicateCard(at: index) },
                                    onMoveUp: index > 0 ? { reorderCard(from: index, to: index - 1) } : nil,
                                    onMoveDown: index < deck.cards.count - 1 ? { reorderCard(from: index, to: index + 2) } : nil
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

            // Delete deck button pinned to bottom
            if appState.decks.count > 1 {
                Rectangle().fill(Theme.editorBorder).frame(height: 1)

                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Delete Deck")
                            .font(.caption2)
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete deck")
                .accessibilityHint("Deletes \(appState.currentDeck?.title ?? "the current deck") permanently")
                .alert("Delete Deck", isPresented: $showDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        deleteCurrentDeck()
                    }
                } message: {
                    Text("Are you sure you want to delete \"\(appState.currentDeck?.title ?? "this deck")\"? This action cannot be undone.")
                }
            }
        }
        .frame(width: 220)
        .background(Theme.sidebarBackground)
    }

    // MARK: - Subviews

    private var deckPickerSection: some View {
        VStack(spacing: 8) {
            // Header row
            HStack {
                Text("Deck")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.editorTextSecondary)

                Spacer()

                Text("\(appState.decks.count)/\(AppState.maxDecks)")
                    .font(.caption2)
                    .foregroundColor(Theme.editorTextSecondary.opacity(0.7))
            }

            // Current deck row with add button
            HStack(spacing: 0) {
                // Deck row: tappable title + chevron toggle
                HStack(spacing: 0) {
                    // Icon + title area (click to rename)
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                            .accessibilityHidden(true)

                        if isEditingDeckTitle {
                            TextField("Deck name", text: $editingDeckTitle, onCommit: {
                                commitDeckTitleEdit()
                            })
                            .font(.footnote.weight(.medium))
                            .textFieldStyle(.plain)
                            .onExitCommand {
                                isEditingDeckTitle = false
                            }
                        } else {
                            Text(appState.currentDeck?.title ?? "Select Deck")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(Theme.editorTextPrimary)
                                .lineLimit(1)
                                .onTapGesture {
                                    editingDeckTitle = appState.currentDeck?.title ?? ""
                                    isEditingDeckTitle = true
                                }
                        }
                    }

                    Spacer()

                    // Chevron (click to expand/collapse deck list)
                    Button(action: {
                        if isEditingDeckTitle {
                            commitDeckTitleEdit()
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDeckListExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(Theme.editorTextSecondary)
                            .rotationEffect(.degrees(isDeckListExpanded ? 90 : 0))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isDeckListExpanded ? "Collapse deck list" : "Expand deck list")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.editorBorder, lineWidth: 1)
                )
                .frame(maxWidth: .infinity)

                Spacer()

                // Add deck button
                Button(action: { showNewDeckDialog = true }) {
                    Image(systemName: "plus")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(appState.canCreateNewDeck ? Theme.editorTextPrimary : Theme.editorTextSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!appState.canCreateNewDeck)
                .frame(width: 24, height: 24)
                .accessibilityLabel("Add deck")
                .accessibilityHint(appState.canCreateNewDeck ? "Creates a new deck" : "Maximum deck limit reached")
            }

            // Collapsible deck list
            if isDeckListExpanded {
                VStack(spacing: 2) {
                    ForEach(appState.decks) { deck in
                        Button(action: {
                            switchToDeck(deck)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDeckListExpanded = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                if deck.id == appState.currentDeck?.id {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(Theme.accent)
                                        .frame(width: 14)
                                        .accessibilityHidden(true)
                                } else {
                                    Spacer()
                                        .frame(width: 14)
                                }

                                Text(deck.title)
                                    .font(.footnote.weight(.medium))
                                    .foregroundColor(deck.id == appState.currentDeck?.id ? Theme.accent : Theme.editorTextPrimary)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(deck.id == appState.currentDeck?.id ? Theme.accent.opacity(0.1) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(deck.title)
                        .accessibilityValue(deck.id == appState.currentDeck?.id ? "Selected" : "")
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .sheet(isPresented: $showNewDeckDialog) {
            NewDeckSheet(isPresented: $showNewDeckDialog)
        }
    }

    private var sidebarHeader: some View {
        HStack {
            Text("Cards")
                .font(.callout.weight(.semibold))
                .foregroundColor(Theme.editorTextPrimary)

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
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Theme.accent)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 24, height: 24)
            .accessibilityLabel("Add card")
            .accessibilityHint("Choose a layout type for the new card")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 40))
                .foregroundColor(Theme.editorTextSecondary)
                .accessibilityHidden(true)

            Text("No Cards")
                .font(.callout.weight(.semibold))
                .foregroundColor(Theme.editorTextSecondary)

            Text("Click + to add a card")
                .font(.footnote)
                .foregroundColor(Theme.editorTextSecondary.opacity(0.7))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No cards. Click the add button to add a card.")
    }

    // MARK: - Actions

    private func commitDeckTitleEdit() {
        let trimmed = editingDeckTitle.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, var deck = appState.currentDeck {
            deck.title = trimmed
            deck.updatedAt = Date()
            appState.currentDeck = deck
            appState.saveDeck()
        }
        isEditingDeckTitle = false
    }

    private func addCard(layout: LayoutType) {
        let newCard = Card(layout: layout)
        appState.addCard(newCard)

        // Select the new card
        if let deck = appState.currentDeck {
            selectedIndex = deck.cards.count - 1
        }
    }

    private func deleteCard(at index: Int) {
        guard let deck = appState.currentDeck, !deck.cards.isEmpty else { return }

        appState.deleteCard(at: index)

        // Re-fetch deck to get updated count after deletion
        guard let updatedDeck = appState.currentDeck else { return }

        // Adjust selection if it's now out of bounds
        if selectedIndex >= updatedDeck.cards.count {
            selectedIndex = max(0, updatedDeck.cards.count - 1)
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
        // Account for index shift when moving forward (destination adjusts after removal)
        if sourceIndex < destinationIndex {
            selectedIndex = destinationIndex - 1
        } else {
            selectedIndex = destinationIndex
        }
    }

    private func switchToDeck(_ deck: Deck) {
        appState.switchToDeck(deck)
        selectedIndex = 0
    }

    private func deleteCurrentDeck() {
        guard let deck = appState.currentDeck else { return }
        appState.deleteDeck(deck)
        selectedIndex = 0
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
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Layout icon
                Image(systemName: card.layout.iconName)
                    .font(.callout)
                    .foregroundColor(isSelected ? Theme.accent : Theme.editorTextSecondary)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                // Card info
                VStack(alignment: .leading, spacing: 2) {
                    Text(cardTitle)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(Theme.editorTextPrimary)
                        .lineLimit(1)

                    Text(card.layout.displayName)
                        .font(.caption2)
                        .foregroundColor(Theme.editorTextSecondary)
                }

                Spacer()

                // Card number
                Text("\(index + 1)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Theme.editorTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.secondaryAccent.opacity(0.14))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.accent.opacity(0.2) : (isHovered ? Theme.surfaceBackground.opacity(0.25) : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.editorBorder.opacity(isHovered ? 1 : 0), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("\(cardTitle), \(card.layout.displayName)")
        .accessibilityValue(isSelected ? "Selected, card \(index + 1)" : "Card \(index + 1)")
        .accessibilityHint("Double-click to select")
        .contextMenu {
            if let onMoveUp = onMoveUp {
                Button(action: onMoveUp) {
                    Label("Move Up", systemImage: "arrow.up")
                }
            }
            if let onMoveDown = onMoveDown {
                Button(action: onMoveDown) {
                    Label("Move Down", systemImage: "arrow.down")
                }
            }
            Divider()
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

// MARK: - New Deck Sheet

struct NewDeckSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    @State private var deckTitle: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("New Deck")
                .font(Theme.note.weight(.semibold))
                .foregroundColor(Theme.editorTextPrimary)

            TextField("Deck Title", text: $deckTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 250)

            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createDeck()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(deckTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .onAppear {
            deckTitle = "Deck \(appState.decks.count + 1)"
        }
    }

    private func createDeck() {
        let title = deckTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        appState.createNewDeck(title: title)
        isPresented = false
    }
}
