import SwiftUI
import UIKit
import AVFoundation

// MARK: - App Entry Point

@main
struct VibriaApp: App {
    /// Bridges UIKit app lifecycle (UIApplicationDelegate) into SwiftUI.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Shared language/localization manager injected into the environment.
    @StateObject private var lang = Lang.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(lang)
        }
    }
}

// MARK: - UIApplicationDelegate (Audio Session + Termination Cleanup)

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Configure audio for background playback.
        // Using `.playback` allows audio to continue when the app goes to background
        // (and enables Control Center / lock screen controls).
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Hard cut when the process is terminated:
        // - detach current player item
        // - clear Now Playing info
        // - force-reset the audio session to stop any lingering playback
        MusicPlayerViewModel.shared.hardStopAndSilence()
    }
}
