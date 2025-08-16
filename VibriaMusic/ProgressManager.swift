import Foundation

final class ProgressManager {
    static let shared = ProgressManager()
    private let threshold: Double = 5.0
    private let maxEntries = 200   // <--- LIMIT
    private var lastSavedPositions: [String: Double] = [:]
    private let userDefaults = UserDefaults.standard
    private let progressKeysListKey = "progressKeysList"

    private init() {}

    // Główna funkcja do zapisu progresu z limitem
    func saveProgressIfNeeded(for songID: String, position: Double) {
        let lastPosition = lastSavedPositions[songID] ?? -1
        let delta = abs(position - lastPosition)
        if lastPosition < 0 || delta > threshold {
            saveProgress(for: songID, position: position)
            lastSavedPositions[songID] = position
            print("💾 Zapisano progres dla: \(songID) (poz: \(Int(position))s, delta: \(Int(delta))s)")
        } else {
            print("⏩ Pominięto zapis progresu dla: \(songID) (poz: \(Int(position))s, delta: \(Int(delta))s)")
        }
    }

    func saveProgress(for songID: String, position: Double) {
        // 1. Zapisz progres
        userDefaults.set(position, forKey: "progress-\(songID)")

        // 2. Zaktualizuj listę wszystkich progresów
        var keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        // Usuń jeśli już istnieje (będziemy trzymać „od najnowszych”)
        keys.removeAll { $0 == songID }
        keys.append(songID)

        // 3. ROTACJA: jeśli jest za dużo progresów — kasuj najstarsze
        if keys.count > maxEntries {
            let toDelete = keys.prefix(keys.count - maxEntries)
            for oldID in toDelete {
                userDefaults.removeObject(forKey: "progress-\(oldID)")
            }
            keys = Array(keys.suffix(maxEntries))
        }

        userDefaults.set(keys, forKey: progressKeysListKey)
    }

    func loadProgress(for songID: String) -> Double {
        return userDefaults.double(forKey: "progress-\(songID)")
    }

    func clearProgress(for songID: String) {
        userDefaults.removeObject(forKey: "progress-\(songID)")
        lastSavedPositions[songID] = nil

        // Usuń z listy progresów
        var keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        keys.removeAll { $0 == songID }
        userDefaults.set(keys, forKey: progressKeysListKey)

        print("🧹 Wyczyszczono progres dla: \(songID)")
    }

    func clearAllProgress() {
        let keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        for songID in keys {
            userDefaults.removeObject(forKey: "progress-\(songID)")
        }
        userDefaults.removeObject(forKey: progressKeysListKey)
        lastSavedPositions.removeAll()
        print("🧹 Wyczyszczono wszystkie progresy")
    }
}
