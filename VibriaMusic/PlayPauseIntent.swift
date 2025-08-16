import AppIntents

struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Odtwórz/Pauzuj muzykę"

    func perform() async throws -> some IntentResult {
        // Najprościej: dostęp do shared ViewModel przez Singleton lub inne metody
        await MainActor.run {
            MusicPlayerViewModel.shared.playPause()
        }
        return .result()
    }
}
