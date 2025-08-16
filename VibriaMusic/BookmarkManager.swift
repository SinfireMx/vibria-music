import Foundation

struct BookmarkManager {
    static let key = "savedBookmarks"

    static func save(urls: [URL]) {
        let dataArray: [Data] = urls.compactMap { url in
            guard url.startAccessingSecurityScopedResource() else { return nil }
            defer { url.stopAccessingSecurityScopedResource() }
            return try? url.bookmarkData()
        }
        // ⬇️ ZAWSZE zapisuje – także pustą tablicę
        UserDefaults.standard.set(dataArray, forKey: key)
        print("💾 BookmarkManager.save – zapisano \(dataArray.count) pozycji")
    }

    static func clear() {
        // Wystarczy nadpisać pustą tablicą tego samego klucza
        UserDefaults.standard.set([], forKey: key)
        print("🗑️ BookmarkManager.clear – ustawiono pustą tablicę")
    }


    static func load() -> [URL] {
        guard let bookmarkDataArray = UserDefaults.standard.array(forKey: key) as? [Data] else {
            print("📦 Brak zakładek do przywrócenia")
            return []
        }

        print("📦 Odczytano \(bookmarkDataArray.count) zakładek z UserDefaults")
        var urls: [URL] = []
        for data in bookmarkDataArray {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
                urls.append(url)
            } catch {
                print("❌ Błąd przywracania zakładki: \(error.localizedDescription)")
            }
        }
        return urls
    }


}
