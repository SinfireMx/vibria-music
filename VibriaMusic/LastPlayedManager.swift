import Foundation

struct LastPlayedManager {
    static let urlKey = "lastPlayedURLBookmark"
    static let timeKey = "lastPlayedTime"
    
    static func save(url: URL, time: Double) {
        // Tworzymy bookmarkData i zapisujemy w UserDefaults
        guard let data = try? url.bookmarkData() else { return }
        UserDefaults.standard.set(data, forKey: urlKey)
        UserDefaults.standard.set(time, forKey: timeKey)
    }
    
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
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: urlKey)
        UserDefaults.standard.removeObject(forKey: timeKey)
    }
}
