import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI wrapper around UIDocumentPickerViewController.
/// Used to import local audio files selected by the user.
struct DocumentPicker: UIViewControllerRepresentable {

    /// Callback returning validated file URLs selected by the user.
    var onFilesPicked: ([URL]) -> Void

    /// Allowed audio file types for the document picker.
    /// Includes common audio formats supported by the app.
    private let allowedAudioTypes: [UTType] = [
        .mp3,
        .wav,
        .aiff,
        UTType(importedAs: "com.apple.protected-mpeg-4-audio"), // m4a
        UTType(importedAs: "com.apple.coreaudio-format"),       // caf
        UTType(importedAs: "public.aifc")                       // aifc
    ]

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilesPicked: onFilesPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Configure system document picker for audio file import.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedAudioTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {
        // No updates required after initial presentation.
    }

    // MARK: - Coordinator

    /// Coordinator bridging UIDocumentPickerDelegate callbacks to SwiftUI.
    class Coordinator: NSObject, UIDocumentPickerDelegate {

        /// Callback forwarding validated URLs back to the SwiftUI layer.
        let onFilesPicked: ([URL]) -> Void

        init(onFilesPicked: @escaping ([URL]) -> Void) {
            self.onFilesPicked = onFilesPicked
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            // Additional safety filter based on file extensions.
            // Ensures only supported audio files are passed to the app logic.
            let supportedExtensions = ["mp3", "wav", "aiff", "aifc", "m4a", "caf"]
            let filtered = urls.filter {
                supportedExtensions.contains($0.pathExtension.lowercased())
            }

            onFilesPicked(filtered)
        }

        func documentPickerWasCancelled(
            _ controller: UIDocumentPickerViewController
        ) {
            // User cancelled file selection.
            print("DocumentPicker cancelled by user")
        }
    }
}
