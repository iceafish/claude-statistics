import Foundation

/// Manages a repeating auto-refresh loop using a detached Task.
/// The caller supplies a closure to run on each tick.
final class AutoRefreshCoordinator: @unchecked Sendable {
    private var refreshTask: Task<Void, Never>?
    private var activeInterval: TimeInterval = 0
    private let action: @Sendable () async -> Void

    /// - Parameter action: The async closure to execute on each tick.
    init(action: @escaping @Sendable () async -> Void) {
        self.action = action
    }

    /// Starts auto-refresh at the given interval (in seconds).
    /// If already running with the same interval, this is a no-op.
    func start(interval: TimeInterval) {
        if refreshTask != nil && activeInterval == interval {
            return
        }
        stop()
        activeInterval = interval
        let action = self.action
        refreshTask = Task.detached {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await action()
            }
        }
    }

    /// Stops the current auto-refresh loop.
    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
