import Carbon.HIToolbox
import AppKit
import Combine

/// Manages system-wide global hotkeys using a CGEvent tap.
///
/// This service:
/// - Registers hotkeys that work even when other apps are focused
/// - Handles hotkey events and dispatches to callbacks
/// - Supports registration/unregistration lifecycle
/// - Requires Accessibility permissions (prompted automatically on first launch)
final class HotkeyManager: ObservableObject {

    // MARK: - Singleton

    static let shared = HotkeyManager()

    // MARK: - Hotkey Definitions

    /// All supported hotkey actions
    enum HotkeyAction: String, CaseIterable {
        case toggleOverlay       // Cmd+Shift+O
        case nextCard            // Cmd+Shift+Right
        case previousCard        // Cmd+Shift+Left
        case increaseFontSize    // Cmd+Shift+=
        case decreaseFontSize    // Cmd+Shift+-
        case scrollUp            // Cmd+Shift+Up
        case scrollDown          // Cmd+Shift+Down
        case toggleClickThrough  // Cmd+Shift+C
        case toggleProtectedMode // Cmd+Shift+P
        case increaseOpacity     // Cmd+Shift+]
        case decreaseOpacity     // Cmd+Shift+[
        case toggleTimer         // Cmd+Shift+T

        /// The virtual key code for this action
        var keyCode: UInt32 {
            switch self {
            case .toggleOverlay:       return UInt32(kVK_ANSI_O)
            case .nextCard:            return UInt32(kVK_RightArrow)
            case .previousCard:        return UInt32(kVK_LeftArrow)
            case .increaseFontSize:    return UInt32(kVK_ANSI_Equal)
            case .decreaseFontSize:    return UInt32(kVK_ANSI_Minus)
            case .scrollUp:            return UInt32(kVK_UpArrow)
            case .scrollDown:          return UInt32(kVK_DownArrow)
            case .toggleClickThrough:  return UInt32(kVK_ANSI_C)
            case .toggleProtectedMode: return UInt32(kVK_ANSI_P)
            case .increaseOpacity:     return UInt32(kVK_ANSI_RightBracket)
            case .decreaseOpacity:     return UInt32(kVK_ANSI_LeftBracket)
            case .toggleTimer:         return UInt32(kVK_ANSI_T)
            }
        }

        /// Modifier flags for this action (Cmd+Shift for all)
        var modifiers: CGEventFlags {
            return [.maskCommand, .maskShift]
        }

        /// Human-readable shortcut string
        var displayString: String {
            switch self {
            case .toggleOverlay:       return "⌘⇧O"
            case .nextCard:            return "⌘⇧→"
            case .previousCard:        return "⌘⇧←"
            case .increaseFontSize:    return "⌘⇧="
            case .decreaseFontSize:    return "⌘⇧-"
            case .scrollUp:            return "⌘⇧↑"
            case .scrollDown:          return "⌘⇧↓"
            case .toggleClickThrough:  return "⌘⇧C"
            case .toggleProtectedMode: return "⌘⇧P"
            case .increaseOpacity:     return "⌘⇧]"
            case .decreaseOpacity:     return "⌘⇧["
            case .toggleTimer:         return "⌘⇧T"
            }
        }
    }

    // MARK: - Properties

    /// The CGEvent tap port
    private var eventTap: CFMachPort?

    /// The run loop source for the event tap
    private var runLoopSource: CFRunLoopSource?

    /// Callbacks for each hotkey action
    private var actionCallbacks: [HotkeyAction: () -> Void] = [:]

    /// Whether hotkeys are currently registered
    @Published private(set) var isRegistered: Bool = false

    /// Whether we've already prompted for Accessibility this app launch
    private var hasPromptedAccessibilityThisLaunch = false

    /// UserDefaults key for throttling Accessibility prompt frequency
    private static let lastAccessibilityPromptAtKey = "PrompterLastAccessibilityPromptAt"

    /// Minimum interval between automatic Accessibility prompts
    private let accessibilityPromptCooldown: TimeInterval = 12 * 60 * 60

    /// Lookup table mapping key codes to actions for fast matching
    private let keyCodeToAction: [UInt32: HotkeyAction] = {
        var map: [UInt32: HotkeyAction] = [:]
        for action in HotkeyAction.allCases {
            map[action.keyCode] = action
        }
        return map
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Registers all global hotkeys via a CGEvent tap.
    ///
    /// Requires Accessibility permissions. If not granted, the system will
    /// prompt the user and registration will be skipped until retried.
    /// - Parameter promptIfNeeded: Whether to allow a system permission prompt.
    ///   Retries should typically pass `false` to avoid repeatedly opening Settings.
    func registerAllHotkeys(promptIfNeeded: Bool = false) {
        guard !isRegistered else {
            print("Hotkeys already registered")
            return
        }

        // Check accessibility permissions and throttle automatic prompts to avoid pop-up loops.
        let shouldPrompt = promptIfNeeded && shouldPromptForAccessibility()
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): shouldPrompt] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            if shouldPrompt {
                recordAccessibilityPrompt()
            }
            print("Accessibility permission not granted — hotkeys not registered")
            return
        }

        // Create event tap for keyDown events
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: HotkeyManager.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create CGEvent tap — verify Accessibility and Input Monitoring permissions")
            return
        }

        eventTap = tap

        // Add to the current run loop
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        isRegistered = true
        print("Global hotkeys registered successfully (CGEvent tap)")
    }

    // MARK: - Permission Prompt Management

    /// Avoid repeatedly opening the Accessibility prompt/settings flow.
    private func shouldPromptForAccessibility() -> Bool {
        guard !hasPromptedAccessibilityThisLaunch else { return false }

        let defaults = UserDefaults.standard
        if let lastPromptAt = defaults.object(forKey: Self.lastAccessibilityPromptAtKey) as? Date,
           Date().timeIntervalSince(lastPromptAt) < accessibilityPromptCooldown {
            return false
        }
        return true
    }

    private func recordAccessibilityPrompt() {
        hasPromptedAccessibilityThisLaunch = true
        UserDefaults.standard.set(Date(), forKey: Self.lastAccessibilityPromptAtKey)
    }

    /// Unregisters all global hotkeys
    func unregisterAllHotkeys() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }

        eventTap = nil
        isRegistered = false
        print("Global hotkeys unregistered")
    }

    // MARK: - Callbacks

    /// Sets the callback for a specific hotkey action
    func setCallback(for action: HotkeyAction, callback: @escaping () -> Void) {
        actionCallbacks[action] = callback
    }

    /// Binds all hotkey callbacks to the app state
    @MainActor
    func bindToAppState(_ appState: AppState) {
        setCallback(for: .toggleOverlay) { [weak appState] in
            Task { @MainActor in
                appState?.toggleOverlay()
            }
        }

        setCallback(for: .nextCard) { [weak appState] in
            Task { @MainActor in
                appState?.nextCard()
            }
        }

        setCallback(for: .previousCard) { [weak appState] in
            Task { @MainActor in
                appState?.previousCard()
            }
        }

        setCallback(for: .increaseFontSize) { [weak appState] in
            Task { @MainActor in
                appState?.increaseFontSize()
            }
        }

        setCallback(for: .decreaseFontSize) { [weak appState] in
            Task { @MainActor in
                appState?.decreaseFontSize()
            }
        }

        setCallback(for: .scrollUp) { [weak appState] in
            Task { @MainActor in
                appState?.scrollUp()
            }
        }

        setCallback(for: .scrollDown) { [weak appState] in
            Task { @MainActor in
                appState?.scrollDown()
            }
        }

        setCallback(for: .toggleClickThrough) { [weak appState] in
            Task { @MainActor in
                appState?.toggleClickThrough()
            }
        }

        setCallback(for: .toggleProtectedMode) { [weak appState] in
            Task { @MainActor in
                appState?.toggleProtectedMode()
            }
        }

        setCallback(for: .increaseOpacity) { [weak appState] in
            Task { @MainActor in
                appState?.increaseOpacity()
            }
        }

        setCallback(for: .decreaseOpacity) { [weak appState] in
            Task { @MainActor in
                appState?.decreaseOpacity()
            }
        }

        setCallback(for: .toggleTimer) { [weak appState] in
            Task { @MainActor in
                appState?.toggleTimerStartPause()
            }
        }

        print("Hotkey callbacks bound to AppState")
    }

    // MARK: - Event Handling

    /// C-function callback for the CGEvent tap
    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        // Handle tap being disabled by the system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let userInfo = userInfo {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
                manager.reEnableTap()
            }
            return Unmanaged.passUnretained(event)
        }

        guard let userInfo = userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userInfo).takeUnretainedValue()
        return manager.handleEvent(event)
    }

    /// Processes a key event and dispatches matching hotkeys
    private func handleEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags

        // Require both Cmd and Shift
        guard flags.contains(.maskCommand), flags.contains(.maskShift) else {
            return Unmanaged.passUnretained(event)
        }

        // Reject if Ctrl or Option are also held
        if flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))

        guard let action = keyCodeToAction[keyCode] else {
            return Unmanaged.passUnretained(event)
        }

        // Execute the callback on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.actionCallbacks[action]?()
            print("Hotkey triggered: \(action.rawValue)")
        }

        // Consume the event so it doesn't propagate to other apps
        return nil
    }

    /// Re-enables the event tap if the system disabled it
    private func reEnableTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
        print("CGEvent tap re-enabled")
    }

    // MARK: - Cleanup

    deinit {
        unregisterAllHotkeys()
    }
}
