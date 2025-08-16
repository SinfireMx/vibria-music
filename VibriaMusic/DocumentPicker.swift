import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var onFilesPicked: ([URL]) -> Void

    // Lista obsługiwanych typów plików audio
    private let allowedAudioTypes: [UTType] = [
        .mp3,
        .wav,
        .aiff,
        UTType(importedAs: "com.apple.protected-mpeg-4-audio"), // m4a
        UTType(importedAs: "com.apple.coreaudio-format"),       // caf
        UTType(importedAs: "public.aifc")                      // aifc
    ]

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilesPicked: onFilesPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedAudioTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilesPicked: ([URL]) -> Void

        init(onFilesPicked: @escaping ([URL]) -> Void) {
            self.onFilesPicked = onFilesPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Opcjonalnie: dodatkowy filtr na rozszerzenia
            let supportedExtensions = ["mp3", "wav", "aiff", "aifc", "m4a", "caf"]
            let filtered = urls.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            onFilesPicked(filtered)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("📁 Document Picker anulowany")
        }
    }
}
