import Carbon
import AppKit
import Combine

/// Manages system-wide global hotkeys using Carbon Event Manager.
///
/// This service:
/// - Registers hotkeys that work even when other apps are focused
/// - Handles hotkey events and dispatches to callbacks
/// - Supports registration/unregistration lifecycle
///
/// Note: Carbon is technically deprecated but is still the standard
/// approach for global hotkeys on macOS. Many popular apps use it.
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

        /// Modifier keys for this action (Cmd+Shift for all)
        var modifiers: UInt32 {
            return UInt32(cmdKey | shiftKey)
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

    /// Registered hotkey references (for unregistration)
    private var hotkeyRefs: [HotkeyAction: EventHotKeyRef] = [:]

    /// The Carbon event handler reference
    private var eventHandler: EventHandlerRef?

    /// Callbacks for each hotkey action
    private var actionCallbacks: [HotkeyAction: () -> Void] = [:]

    /// Whether hotkeys are currently registered
    @Published private(set) var isRegistered: Bool = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Registers all global hotkeys
    func registerAllHotkeys() {
        guard !isRegistered else {
            print("Hotkeys already registered")
            return
        }

        // Install the event handler
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerResult = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else {
                    return OSStatus(eventNotHandledErr)
                }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotkeyEvent(event)
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard handlerResult == noErr else {
            print("Failed to install hotkey event handler: \(handlerResult)")
            return
        }

        // Register each hotkey
        for (index, action) in HotkeyAction.allCases.enumerated() {
            registerHotkey(action: action, id: UInt32(index + 1))
        }

        isRegistered = true
        print("Global hotkeys registered successfully")
    }

    /// Registers a single hotkey
    private func registerHotkey(action: HotkeyAction, id: UInt32) {
        var hotkeyRef: EventHotKeyRef?

        // Signature: "POVS" (Presenter Overlay)
        let signature = OSType(0x504F5653)
        let hotkeyID = EventHotKeyID(signature: signature, id: id)

        let result = RegisterEventHotKey(
            action.keyCode,
            action.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if result == noErr, let ref = hotkeyRef {
            hotkeyRefs[action] = ref
            print("Registered hotkey: \(action.displayString) for \(action.rawValue)")
        } else {
            print("Failed to register hotkey \(action.displayString): \(result)")
        }
    }

    /// Unregisters all global hotkeys
    func unregisterAllHotkeys() {
        for (action, ref) in hotkeyRefs {
            UnregisterEventHotKey(ref)
            print("Unregistered hotkey: \(action.displayString)")
        }
        hotkeyRefs.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }

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

    /// Handles incoming hotkey events from Carbon
    private func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else {
            return OSStatus(eventNotHandledErr)
        }

        var hotkeyID = EventHotKeyID()
        let result = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )

        guard result == noErr else {
            return result
        }

        // Find the action by ID (1-indexed)
        let index = Int(hotkeyID.id) - 1
        guard index >= 0, index < HotkeyAction.allCases.count else {
            return OSStatus(eventNotHandledErr)
        }

        let action = HotkeyAction.allCases[index]

        // Execute the callback on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.actionCallbacks[action]?()
            print("Hotkey triggered: \(action.rawValue)")
        }

        return noErr
    }

    // MARK: - Cleanup

    deinit {
        unregisterAllHotkeys()
    }
}
