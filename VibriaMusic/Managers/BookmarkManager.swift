import Foundation

/// Manages persistence of user-selected file URLs using security-scoped bookmarks.
/// Allows restoring access to local files across app launches.
struct BookmarkManager {

    /// UserDefaults key used to store bookmark data.
    static let key = "savedBookmarks"

    /// Saves security-scoped bookmarks for the provided file URLs.
    /// An empty array is also persisted to explicitly clear previously stored access.
    static func save(urls: [URL]) {
        let dataArray: [Data] = urls.compactMap { url in
            guard url.startAccessingSecurityScopedResource() else { return nil }
            defer { url.stopAccessingSecurityScopedResource() }

            // Create bookmark data for the selected file URL
            return try? url.bookmarkData()
        }

        // Persist bookmarks (including an empty array)
        UserDefaults.standard.set(dataArray, forKey: key)
        print("BookmarkManager.save – saved \(dataArray.count) items")
    }

    /// Removes all persisted bookmarks by overwriting with an empty array.
    static func clear() {
        UserDefaults.standard.set([], forKey: key)
        print("BookmarkManager.clear – cleared stored bookmarks")
    }

    /// Restores file URLs from previously saved bookmark data.
    static func load() -> [URL] {
        guard let bookmarkDataArray = UserDefaults.standard.array(forKey: key) as? [Data] else {
            print("BookmarkManager.load – no bookmarks found")
            return []
        }

        print("BookmarkManager.load – restoring \(bookmarkDataArray.count) bookmarks")

        var urls: [URL] = []

        for data in bookmarkDataArray {
            var isStale = false
            do {
                // Resolve bookmark data back into a file URL
                let url = try URL(
                    resolvingBookmarkData: data,
                    bookmarkDataIsStale: &isStale
                )
                urls.append(url)
            } catch {
                print("BookmarkManager.load – failed to resolve bookmark: \(error.localizedDescription)")
            }
        }

        return urls
    }
}
