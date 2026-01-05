import SwiftUI

/// UIKit blur wrapper for use in SwiftUI.
/// Allows using `UIVisualEffectView` (native iOS blur)
/// inside SwiftUI layouts.
struct VisualEffectBlur: UIViewRepresentable {

    /// Blur style (e.g. `.systemUltraThinMaterial`, `.dark`, `.light`)
    var blurStyle: UIBlurEffect.Style

    /// Creates the underlying UIKit view.
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    /// Updates the blur style when SwiftUI state changes.
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
