import SwiftUI
import UIKit

struct ShakeDetector: UIViewControllerRepresentable {
    var onShake: () -> Void

    class Coordinator: UIResponder, UIWindowSceneDelegate {
        var onShake: () -> Void

        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake()
            }
        }
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.becomeFirstResponder()
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onShake: onShake)
    }
}
