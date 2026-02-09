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
/// Renders the current card using layout-specific renderers.
struct OverlayContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Frosted glass background (opacity applied here only)
            RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                        .fill(Theme.surfaceBackground.opacity(0.75))
                )
                .opacity(appState.overlayOpacity)

            // Content (always fully opaque)
            VStack(spacing: 0) {
                // Drag handle at top
                DragHandleView()

                // Card content using layout-specific renderer
                if let card = appState.currentCard {
                    ScrollView {
                        OverlayCardRenderer(card: card, fontScale: appState.overlayFontScale)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                } else {
                    emptyState
                }

                Spacer(minLength: 0)

                // Footer with resize hint
                OverlayFooterView()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.overlayCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.overlayCornerRadius)
                .stroke(Theme.divider.opacity(appState.overlayOpacity), lineWidth: 1)
        )
        .shadow(color: Theme.accentGlow.opacity(appState.overlayOpacity), radius: Theme.overlayShadowRadius, x: 0, y: 10)
        .animation(.easeInOut(duration: Theme.cardTransitionDuration), value: appState.currentCardIndex)
        .animation(.easeInOut(duration: 0.15), value: appState.overlayOpacity)
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
}

// MARK: - Drag Handle View

/// A visual drag handle at the top of the overlay for moving the window.
struct DragHandleView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Centered drag indicator
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.textSecondary.opacity(0.5))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)

                Text("Drag to move • Edges to resize")
                    .font(.system(size: Theme.smallFontSize))
                    .foregroundColor(Theme.textSecondary.opacity(0.6))
            }

            // Traffic light buttons (top-left)
            HStack(spacing: 8) {
                TrafficLightButton(color: Theme.trafficLightRed) {
                    appState.toggleOverlay()
                }
                TrafficLightButton(color: Theme.trafficLightDisabled, disabled: true)
                TrafficLightButton(color: Theme.trafficLightDisabled, disabled: true)
                Spacer()
            }
            .padding(.leading, 12)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        .contentShape(Rectangle())
    }
}

/// macOS-style traffic light circle button.
struct TrafficLightButton: View {
    let color: Color
    var disabled: Bool = false
    var action: (() -> Void)? = nil

    @State private var isHovered = false

    private let size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(disabled ? Theme.trafficLightDisabled : color)
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if isHovered && !disabled {
                        Image(systemName: "xmark")
                            .font(.system(size: Theme.iconSmallFontSize, weight: .bold))
                            .foregroundColor(Theme.trafficLightIcon)
                    }
                }
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if !disabled {
                    action?()
                }
            }
    }
}
