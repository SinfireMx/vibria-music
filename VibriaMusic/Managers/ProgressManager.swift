import Foundation

/// Persists playback progress per track in `UserDefaults`.
/// - Saves only when the playback position changes more than `threshold` seconds.
/// - Keeps at most `maxEntries` progress records (LRU-style rotation).
final class ProgressManager {

    static let shared = ProgressManager()

    // MARK: - Configuration

    /// Minimal delta (in seconds) required to write a new progress value.
    private let threshold: Double = 5.0

    /// Max number of stored progress entries (older entries are removed).
    private let maxEntries: Int = 200

    /// UserDefaults key that stores the ordered list of song IDs with saved progress.
    private let progressKeysListKey = "progressKeysList"

    // MARK: - State

    /// In-memory cache to avoid frequent UserDefaults writes.
    /// Key: songID, Value: last saved position in seconds.
    private var lastSavedPositions: [String: Double] = [:]

    private let userDefaults = UserDefaults.standard

    /// Enable/disable debug logging (kept off by default for production polish).
    private let debugLogEnabled = false

    private init() {}

    // MARK: - Public API

    /// Saves progress only if the position changed more than `threshold` seconds since last save.
    func saveProgressIfNeeded(for songID: String, position: Double) {
        let lastPosition = lastSavedPositions[songID] ?? -1
        let delta = abs(position - lastPosition)

        guard lastPosition < 0 || delta > threshold else {
            debugLog("⏩ Skipped progress save for: \(songID) (pos: \(Int(position))s, delta: \(Int(delta))s)")
            return
        }

        saveProgress(for: songID, position: position)
        lastSavedPositions[songID] = position
        debugLog("💾 Saved progress for: \(songID) (pos: \(Int(position))s, delta: \(Int(delta))s)")
    }

    /// Forces a progress save (no threshold check).
    func saveProgress(for songID: String, position: Double) {
        // 1) Store progress value
        userDefaults.set(position, forKey: progressKey(for: songID))

        // 2) Maintain an ordered list of saved progress IDs (LRU: newest at the end)
        var keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        keys.removeAll { $0 == songID }
        keys.append(songID)

        // 3) Rotation: remove oldest entries if we exceed the limit
        if keys.count > maxEntries {
            let overflowCount = keys.count - maxEntries
            let toDelete = keys.prefix(overflowCount)

            for oldID in toDelete {
                userDefaults.removeObject(forKey: progressKey(for: oldID))
            }

            keys = Array(keys.suffix(maxEntries))
        }

        userDefaults.set(keys, forKey: progressKeysListKey)
    }

    /// Loads the saved progress for the given song ID (seconds).
    /// Returns `0` if no saved value exists.
    func loadProgress(for songID: String) -> Double {
        userDefaults.double(forKey: progressKey(for: songID))
    }

    /// Removes saved progress for a single song ID and clears its in-memory cache.
    func clearProgress(for songID: String) {
        userDefaults.removeObject(forKey: progressKey(for: songID))
        lastSavedPositions[songID] = nil

        var keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        keys.removeAll { $0 == songID }
        userDefaults.set(keys, forKey: progressKeysListKey)

        debugLog("🧹 Cleared progress for: \(songID)")
    }

    /// Removes all saved progress values and resets internal cache.
    func clearAllProgress() {
        let keys = userDefaults.stringArray(forKey: progressKeysListKey) ?? []
        for songID in keys {
            userDefaults.removeObject(forKey: progressKey(for: songID))
        }

        userDefaults.removeObject(forKey: progressKeysListKey)
        lastSavedPositions.removeAll()

        debugLog("🧹 Cleared all progress entries")
    }

    // MARK: - Helpers

    private func progressKey(for songID: String) -> String {
        "progress-\(songID)"
    }

    private func debugLog(_ message: String) {
        guard debugLogEnabled else { return }
        print(message)
    }
}
