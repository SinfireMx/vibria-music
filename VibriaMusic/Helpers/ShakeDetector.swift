import SwiftUI
import UIKit

/// A SwiftUI wrapper that detects a physical device shake using UIKit.
///
/// Usage:
/// - Embed this view anywhere in the SwiftUI hierarchy.
/// - Provide an `onShake` callback to react to shake gestures.
///
/// Internally uses `UIResponder.motionEnded` via a custom coordinator.
struct ShakeDetector: UIViewControllerRepresentable {

    /// Called when a shake gesture is detected.
    var onShake: () -> Void

    // MARK: - Coordinator

    /// Coordinator acts as a UIResponder to receive motion events.
    /// Uses UIKit's shake detection and forwards it to SwiftUI.
    class Coordinator: UIResponder, UIWindowSceneDelegate {

        /// Callback executed on shake.
        var onShake: () -> Void

        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
        }

        /// Called by UIKit when a motion event ends.
        /// We filter for `.motionShake`.
        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake()
            }
        }
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        // Required to receive motion events
        controller.becomeFirstResponder()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No dynamic updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onShake: onShake)
    }
}
