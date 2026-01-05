import SwiftUI
import UIKit

/// SwiftUI wrapper for `UIActivityViewController`.
/// Used to present the system Share Sheet from SwiftUI views.
///
/// Example usage:
/// `.sheet(isPresented: $showShare) {
///     ActivityView(activityItems: [url])
/// }`
struct ActivityView: UIViewControllerRepresentable {

    /// Items to be shared (e.g. text, URL, image).
    let activityItems: [Any]

    /// Optional custom UIActivity implementations.
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create and return system Share Sheet controller
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {
        // No updates required.
        // Share sheet configuration is static after presentation.
    }
}
