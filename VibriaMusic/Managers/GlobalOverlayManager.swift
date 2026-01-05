import SwiftUI

/// Manages a global overlay used to indicate background operations
/// (e.g. saving playlists or library state).
///
/// Ensures the overlay:
/// - stays visible while one or more operations are in progress
/// - remains visible for a minimum duration to avoid flickering
class GlobalOverlayManager: ObservableObject {

    static let shared = GlobalOverlayManager()

    /// Controls overlay visibility.
    @Published var visible: Bool = false

    /// Timestamp of the most recent `show()` call.
    private var showTime: Date?

    /// Minimum time the overlay should remain visible once shown.
    private var minVisibleTime: TimeInterval = 1.0

    /// Number of concurrent operations currently in progress.
    /// The overlay is hidden only when this counter reaches zero.
    private var inFlight: Int = 0

    /// Requests the overlay to be shown.
    /// Increments the in-flight counter to support concurrent operations.
    func show() {
        inFlight += 1
        showTime = Date()
        if !visible { visible = true }
    }

    /// Requests the overlay to be hidden.
    /// The overlay is dismissed only when all in-flight operations are completed
    /// and the minimum visible duration has elapsed.
    func hide() {
        // Decrement the in-flight counter if needed.
        if inFlight > 0 { inFlight -= 1 }

        // Do not hide the overlay while other operations are still running.
        guard inFlight == 0 else { return }

        guard let showTime = showTime else {
            visible = false
            return
        }

        let elapsed = Date().timeIntervalSince(showTime)

        if elapsed < minVisibleTime {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + (minVisibleTime - elapsed)
            ) { [weak self] in
                // Hide only if no new operations started in the meantime.
                if self?.inFlight == 0 {
                    self?.visible = false
                }
            }
        } else {
            visible = false
        }
    }
}
