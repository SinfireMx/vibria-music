import AppIntents

/// AppIntent used for Siri / Shortcuts integration.
/// Resumes playback of the last selected track in the Vibria music player.
struct PlayMusicIntent: AppIntent {

    /// Display title shown in Siri and the Shortcuts app.
    static var title: LocalizedStringResource = "Play Music"

    /// Short description explaining what the intent does.
    static var description = IntentDescription(
        "Resumes playback of the last played track in the Vibria app."
    )

    /// Executes the intent.
    /// Playback control must run on the main actor because it interacts
    /// with AVPlayer-backed UI state.
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MusicPlayerViewModel.shared.play()
        }
        return .result()
    }
}
