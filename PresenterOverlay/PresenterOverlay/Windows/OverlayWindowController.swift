import AppKit
import SwiftUI
import Combine

/// Controller managing the overlay window lifecycle.
///
/// Responsibilities:
/// - Create and configure the overlay window
/// - Show/hide the window based on app state
/// - Apply settings (click-through, protected mode)
/// - Persist window frame changes
@MainActor
final class OverlayWindowController: NSObject, ObservableObject {

    // MARK: - Properties

    /// The overlay window (created lazily)
    private var overlayWindow: OverlayWindow?

    /// Reference to the app state
    private var appState: AppState

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
        super.init()
        setupBindings()
    }

    // MARK: - Window Lifecycle

    /// Creates the overlay window (hidden initially)
    func createWindow() {
        guard overlayWindow == nil else { return }

        let frame = appState.overlayFrame.toNSRect()
        overlayWindow = OverlayWindow(
            contentRect: frame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        // Set SwiftUI content
        let contentView = OverlayContentView()
            .environmentObject(appState)

        overlayWindow?.contentView = NSHostingView(rootView: contentView)

        // Apply initial settings
        overlayWindow?.setClickThrough(appState.isClickThroughEnabled)
        overlayWindow?.setProtectedMode(appState.isProtectedModeEnabled)

        // Observe window frame changes for persistence
        setupFrameObservers()

        print("Overlay window created")
    }

    /// Shows the overlay window
    func showWindow() {
        if overlayWindow == nil {
            createWindow()
        }
        overlayWindow?.orderFront(nil)
        print("Overlay window shown")
    }

    /// Hides the overlay window
    func hideWindow() {
        overlayWindow?.orderOut(nil)
        print("Overlay window hidden")
    }

    /// Toggles overlay visibility
    func toggleWindow() {
        if overlayWindow?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }

    /// Closes and releases the overlay window
    func closeWindow() {
        overlayWindow?.close()
        overlayWindow = nil
        print("Overlay window closed")
    }

    // MARK: - Bindings

    /// Sets up reactive bindings to app state
    private func setupBindings() {
        // Visibility binding
        appState.$isOverlayVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] visible in
                if visible {
                    self?.showWindow()
                } else {
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)

        // Click-through binding
        appState.$isClickThroughEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.overlayWindow?.setClickThrough(enabled)
            }
            .store(in: &cancellables)

        // Protected mode binding
        appState.$isProtectedModeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                self?.overlayWindow?.setProtectedMode(enabled)
            }
            .store(in: &cancellables)
    }

    /// Sets up observers for window frame changes
    private func setupFrameObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: overlayWindow
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: overlayWindow
        )
    }

    // MARK: - Frame Persistence

    @objc private func windowDidResize(_ notification: Notification) {
        persistWindowFrame()
    }

    @objc private func windowDidMove(_ notification: Notification) {
        persistWindowFrame()
    }

    /// Saves the current window frame to app state
    private func persistWindowFrame() {
        guard let frame = overlayWindow?.frame else { return }
        let overlayFrame = OverlayFrame.from(frame)
        appState.updateOverlayFrame(overlayFrame)
    }
}

// MARK: - Overlay Content View

/// Root SwiftUI view for the overlay window content.
/// This is a placeholder that will be expanded in Phase 2.
struct OverlayContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Frosted glass background
            RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                        .fill(Theme.surfaceBackground.opacity(0.75))
                )

            VStack(spacing: 0) {
                // Card content
                if let card = appState.currentCard {
                    cardContent(for: card)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                } else {
                    emptyState
                }

                Spacer(minLength: 0)

                // Footer
                footer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.overlayCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                .stroke(Theme.divider, lineWidth: 1)
        )
        .shadow(color: Theme.accentGlow, radius: Theme.overlayShadowRadius, x: 0, y: 10)
    }

    /// Renders card content based on layout
    /// (Placeholder - will be expanded in Phase 2)
    @ViewBuilder
    private func cardContent(for card: Card) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = card.title {
                Text(title)
                    .font(.system(size: Theme.titleFontSize * appState.overlayFontScale, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }

            if let bullets = card.bullets {
                ForEach(Array(bullets.enumerated()), id: \.offset) { index, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(Theme.accent)
                        Text(bullet)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .font(.system(size: Theme.notesFontSize * appState.overlayFontScale))
                }
            }

            if let notes = card.notes {
                Text(notes)
                    .font(.system(size: Theme.notesFontSize * appState.overlayFontScale))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Empty state when no cards exist
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundColor(Theme.accent)

            Text("No Cards")
                .font(.title2)
                .foregroundColor(Theme.textPrimary)

            Text("Open the Deck Editor to create cards")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Footer showing card count and status
    private var footer: some View {
        HStack {
            Text("Card \(appState.currentCardIndex + 1) / \(appState.totalCards)")
                .font(.system(size: Theme.footerFontSize, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            HStack(spacing: 8) {
                if appState.isProtectedModeEnabled {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 12))
                }
                if appState.isClickThroughEnabled {
                    Image(systemName: "cursorarrow.click.badge.clock")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(0.8)
    }
}
