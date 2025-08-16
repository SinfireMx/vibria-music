import SwiftUI

import SwiftUI
import UIKit
import AVFoundation

// MARK: - SwiftUI App
@main
struct VibriaApp: App {
    // Podpinamy AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Udostępniamy wspólny język w całej aplikacji
    @StateObject private var lang = Lang.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(lang)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // normalnie trzymasz kategorię .playback, żeby grało w tle
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // twarde ucięcie przy zabiciu procesu
        MusicPlayerViewModel.shared.hardStopAndSilence()
    }
}
