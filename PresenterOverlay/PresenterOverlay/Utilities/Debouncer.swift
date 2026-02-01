import Foundation

/// A utility for debouncing rapid calls to a function.
///
/// Debouncing ensures that a function is only called once after
/// a specified delay, even if triggered multiple times. This is
/// useful for auto-save functionality where we don't want to save
/// on every keystroke.
///
/// Example usage:
/// ```
/// let debouncer = Debouncer(delay: 0.5)
/// debouncer.debounce {
///     // This will only execute once, 0.5s after the last call
///     saveDocument()
/// }
/// ```
final class Debouncer {

    // MARK: - Properties

    /// The delay in seconds before the action is executed
    private let delay: TimeInterval

    /// The queue to execute the action on
    private let queue: DispatchQueue

    /// The current pending work item
    private var workItem: DispatchWorkItem?

    /// The current pending action (kept separately for flush)
    private var pendingAction: (() -> Void)?

    /// Lock for thread safety
    private let lock = NSLock()

    // MARK: - Initialization

    /// Creates a new debouncer
    /// - Parameters:
    ///   - delay: The delay in seconds (default: 0.5)
    ///   - queue: The queue to execute on (default: main)
    init(delay: TimeInterval = 0.5, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    // MARK: - Public Methods

    /// Debounces the given action
    ///
    /// If called multiple times within the delay period, only the
    /// last call's action will be executed.
    ///
    /// - Parameter action: The action to execute after the delay
    func debounce(_ action: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        // Cancel any pending work
        workItem?.cancel()

        // Store the action for potential flush
        pendingAction = action

        // Create new work item
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.pendingAction = nil
            self.workItem = nil
            self.lock.unlock()
            action()
        }
        workItem = item

        // Schedule execution after delay
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancels any pending debounced action
    func cancel() {
        lock.lock()
        defer { lock.unlock() }

        workItem?.cancel()
        workItem = nil
        pendingAction = nil
    }

    /// Executes the pending action immediately if one exists
    func flush() {
        lock.lock()
        let action = pendingAction
        pendingAction = nil
        workItem?.cancel()
        workItem = nil
        lock.unlock()

        // Execute the action directly
        action?()
    }
}
