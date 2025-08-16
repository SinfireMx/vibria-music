import AppIntents

struct PlayMusicIntent: AppIntent {
    static var title: LocalizedStringResource = "Włącz muzykę"
    static var description = IntentDescription("Odtwórz ostatni utwór lub wznow odtwarzanie muzyki w aplikacji Vibria.")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            MusicPlayerViewModel.shared.play()
        }
        return .result()
    }
}
