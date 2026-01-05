import Foundation

/// Persists information about the last played track and playback position.
/// Used to restore playback state on app relaunch.
struct LastPlayedManager {
    
    /// UserDefaults key for the bookmarked URL of the last played track.
    static let urlKey = "lastPlayedURLBookmark"
    
    /// UserDefaults key for the last playback time (in seconds).
    static let timeKey = "lastPlayedTime"
    
    /// Saves the currently playing track and playback position.
    static func save(url: URL, time: Double) {
        // Store a security-scoped bookmark to restore access on next launch.
        guard let data = try? url.bookmarkData() else { return }
        UserDefaults.standard.set(data, forKey: urlKey)
        UserDefaults.standard.set(time, forKey: timeKey)
    }
    
    /// Loads the last played track and playback position.
    /// Returns `(nil, 0)` when no previous state is available.
    static func load() -> (URL?, Double) {
        guard let data = UserDefaults.standard.data(forKey: urlKey) else {
            return (nil, 0)
        }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) {
            let time = UserDefaults.standard.double(forKey: timeKey)
            return (url, time)
        }
        return (nil, 0)
    }
    
    /// Clears persisted playback state.
    static func clear() {
        UserDefaults.standard.removeObject(forKey: urlKey)
        UserDefaults.standard.removeObject(forKey: timeKey)
    }
}
