import AppIntents

/// AppIntent used for Siri / Shortcuts integration.
/// Toggles playback state (play ↔ pause) in the Vibria music player.
struct PlayPauseIntent: AppIntent {

    /// Display title shown in Siri and the Shortcuts app.
    static var title: LocalizedStringResource = "Play or Pause Music"

    /// Executes the intent.
    /// Runs on the main actor because it interacts with AVPlayer-backed state.
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MusicPlayerViewModel.shared.playPause()
        }
        return .result()
    }
}
