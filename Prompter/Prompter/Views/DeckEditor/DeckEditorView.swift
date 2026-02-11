import SwiftUI

/// Main deck editor view with sidebar and canvas.
///
/// Layout:
/// - Left: Card list sidebar with add/delete/reorder
/// - Right: Card canvas showing the selected card's editor
struct DeckEditorView: View {
    @EnvironmentObject var appState: AppState

    /// Index of the currently selected card
    @State private var selectedCardIndex: Int = 0

    /// Whether to show the deck settings sheet
    @State private var showDeckSettings = false

    var body: some View {
        HSplitView {
            // Sidebar
            CardListSidebar(selectedIndex: $selectedCardIndex)

            // Canvas
            CardCanvasView(selectedIndex: $selectedCardIndex)
                .frame(minWidth: 500)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Preview in overlay button
                Button(action: toggleOverlayPreview) {
                    Label(
                        appState.isOverlayVisible ? "Hide Overlay" : "Show Overlay",
                        systemImage: appState.isOverlayVisible ? "eye.slash" : "eye"
                    )
                }

                // Deck settings
                Button(action: { showDeckSettings = true }) {
                    Label("Deck Settings", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showDeckSettings) {
            DeckSettingsSheet()
        }
        .onAppear {
            ensureDeckExists()
            syncSelectionWithAppState()
        }
        .onChange(of: selectedCardIndex) { _, newIndex in
            // Update app state when selection changes
            appState.navigateToCard(newIndex)
        }
    }

    // MARK: - Actions

    private func ensureDeckExists() {
        if appState.currentDeck == nil {
            // Create a new deck with one default card
            let deck = Deck(title: "New Deck", cards: [
                Card(layout: .titleBullets, title: "Welcome", bullets: ["Your first card"])
            ])
            appState.loadDeck(deck)
        }
    }

    private func syncSelectionWithAppState() {
        selectedCardIndex = appState.currentCardIndex
    }

    private func toggleOverlayPreview() {
        appState.toggleOverlay()
    }
}

// MARK: - Card Canvas View

/// The main editing area showing the selected card's layout editor
struct CardCanvasView: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedIndex: Int

    var body: some View {
        ZStack {
            // Background
            Theme.canvasBackground

            if let deck = appState.currentDeck,
               selectedIndex >= 0 && selectedIndex < deck.cards.count {
                let card = deck.cards[selectedIndex]

                VStack(spacing: 0) {
                    // Card header with layout picker
                    cardHeader(for: card)

                    Divider()

                    // Layout-specific editor
                    ScrollView {
                        layoutEditor(for: card)
                            .padding(24)
                    }
                }
            } else {
                // No card selected
                noCardSelected
            }
        }
    }

    // MARK: - Subviews

    private func cardHeader(for card: Card) -> some View {
        HStack {
            // Layout type picker
            Picker("Layout", selection: layoutBinding(for: card)) {
                ForEach(LayoutType.allCases) { layout in
                    Label(layout.displayName, systemImage: layout.iconName)
                        .tag(layout)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

            Spacer()

            // Card position indicator
            if let deck = appState.currentDeck {
                Text("Card \(selectedIndex + 1) of \(deck.cards.count)")
                    .font(.system(size: Theme.footerFontSize, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.cardBackground.opacity(0.5))
    }

    @ViewBuilder
    private func layoutEditor(for card: Card) -> some View {
        switch card.layout {
        case .titleBullets:
            TitleBulletsEditorView(card: cardBinding(for: card))
        case .titleNotes:
            TitleNotesEditorView(card: cardBinding(for: card))
        case .imageTopNotes:
            ImageTopNotesEditorView(card: cardBinding(for: card))
        case .twoImagesNotes:
            TwoImagesNotesEditorView(card: cardBinding(for: card))
        case .grid2x2Caption:
            Grid2x2CaptionEditorView(card: cardBinding(for: card))
        case .fullBleedBullets:
            FullBleedBulletsEditorView(card: cardBinding(for: card))
        }
    }

    private var noCardSelected: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.dashed")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary)

            Text("No Card Selected")
                .font(.system(size: Theme.titleFontSize, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            Text("Select a card from the sidebar or create a new one")
                .font(.system(size: Theme.notesFontSize, weight: .regular))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
    }

    // MARK: - Bindings

    private func cardBinding(for card: Card) -> Binding<Card> {
        Binding(
            get: {
                if let deck = appState.currentDeck,
                   selectedIndex >= 0 && selectedIndex < deck.cards.count {
                    return deck.cards[selectedIndex]
                }
                return card
            },
            set: { newCard in
                appState.updateCard(newCard, at: selectedIndex)
            }
        )
    }

    private func layoutBinding(for card: Card) -> Binding<LayoutType> {
        Binding(
            get: { card.layout },
            set: { newLayout in
                var updatedCard = card
                updatedCard.layout = newLayout
                appState.updateCard(updatedCard, at: selectedIndex)
            }
        )
    }
}

// MARK: - Deck Settings Sheet

struct DeckSettingsSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var deckTitle: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Deck Settings")
                .font(.system(size: Theme.titleFontSize, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Form {
                TextField("Deck Title", text: $deckTitle)
                    .font(.system(size: Theme.notesFontSize, weight: .regular))
                    .textFieldStyle(.roundedBorder)
            }
            .formStyle(.grouped)
            .frame(width: 300)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveDeckSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .onAppear {
            deckTitle = appState.currentDeck?.title ?? "New Deck"
        }
    }

    private func saveDeckSettings() {
        if var deck = appState.currentDeck {
            deck.title = deckTitle
            deck.updatedAt = Date()
            appState.currentDeck = deck
            appState.saveDeck()
        }
    }
}

#Preview {
    DeckEditorView()
        .environmentObject(AppState())
        .frame(width: 900, height: 600)
}
