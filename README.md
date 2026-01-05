# Vibria Music

Native iOS audio player built with Swift & SwiftUI.

![Player](screenshots/player.png)
![Playlists](screenshots/playlists.png)
![Triangle UI](screenshots/triangle.png)

Vibria Music is a native iOS audio player built with Swift and SwiftUI, focused on offline playback of local audio files imported via the system Files app.

The app explores a non-standard triangular navigation UI, where rotating an equilateral triangle switches between three main sections.

This project was built as a learning and portfolio application, with strong emphasis on audio handling, state management, persistence, and system-level iOS integration.


---

## ✨ Features

- 🎵 Offline playback of local audio files  
  *(mp3, m4a, aac, wav, aiff, caf)*

- 📂 File import via `UIDocumentPicker` (Files / iCloud Drive)
- 🔐 Security-scoped bookmarks for persistent access to user-selected files
- 🔺 Custom triangular navigation UI with smooth rotation animations
- ▶️ Now Playing screen
  - Play / Pause
  - Next / Previous
  - Progress slider with seeking
- ⏱️ Playback progress persistence (resume from last position)
- ❤️ Favorites (bookmarks) and user playlists
- 📑 Add tracks to playlists via overlay UI
- 🔁 Background audio playback
- 🎛️ Lock Screen & Control Center controls (`MPRemoteCommandCenter`)
- ⚙️ Lightweight settings for UI & playback behavior

---

## 🧱 Architecture Overview

- SwiftUI used for the entire UI layer
- MVVM-style structure

### Core ViewModel

**MusicPlayerViewModel**
- Manages `AVPlayer`
- Handles playback state, progress tracking, and queue logic
- Integrates with `MPRemoteCommandCenter`

### Managers (single-responsibility)

- **PlaylistsManager** – playlists & favorites
- **ProgressManager** – playback progress persistence
- **BookmarkManager** – security-scoped file access

### Persistence

- Imported files: security-scoped bookmarks stored in `UserDefaults`
- Playlists: `Codable` → JSON stored in `UserDefaults`
- Playback progress: lightweight `UserDefaults` storage with entry rotation (memory-safe)

---

## 📁 Key Components

- **TrueTriangleTabView**  
  Triangular tab system with rotation animation

- **ContentView**  
  App entry point, restores library and last playback state

- **MusicPlayerViewModel**  
  Core audio logic (`AVFoundation` + `MediaPlayer`)

- **DocumentPicker**  
  Local file import

- **PlaylistsManager**  
  Playlist creation, editing, persistence

- **ProgressManager**  
  Resume logic and progress tracking

---

## ▶️ Running the Project

1. Open `VibriaMusic.xcodeproj` in Xcode  
2. Select a simulator or physical iPhone  
3. Build & Run  

**In-app usage:**
- Tap “+” in the song list to import audio files
- Select a track to start playback
- Switch views by tapping triangle corners

---

## 🔒 Privacy

Vibria Music works fully offline.

- No analytics
- No network requests
- No third-party SDKs

All data (playlists, progress, bookmarks) is stored locally on the device.

---

## 🧪 Handled Edge Cases

- Missing or deleted files (graceful handling, no crashes)
- Large libraries – optional reduced animations for performance
- App backgrounding / foregrounding with active playback

---

## 🗺️ Roadmap

- Improved metadata parsing
- Search & sorting for large libraries
- Better UI feedback for unavailable files

---

## 👤 Author

**Mariusz**  
iOS Developer (Swift / SwiftUI)

**Tech stack:**  
Swift · SwiftUI · AVFoundation · MediaPlayer · Combine
