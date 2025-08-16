import SwiftUI

struct DrawerSidebar: View {
    var onSearch: () -> Void
    var onAddSongs: () -> Void
    var onManagePlaylists: () -> Void
    var onCollapse: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Button(action: { onSearch() }) {
                Image(systemName: "magnifyingglass").iconSquareBG
            }
            Button(action: { onAddSongs() }) {
                Image(systemName: "plus").iconSquareBG
            }
            Button(action: { onManagePlaylists() }) {
                Image(systemName: "music.note.list").iconSquareBG
            }
            Spacer()
            Button(action: { onCollapse() }) {
                Image(systemName: "chevron.left").iconSquareBG
            }
        }
        .padding(.top, 36)
        .padding(.horizontal, 6)
        .frame(width: 52)
        .background(Color(.systemGray6).opacity(0.50))
    }
}
// Helper
extension Image {
    var iconSquareBG: some View {
        self
            .resizable()
            .scaledToFit()
            .padding(10)
            .frame(width: 38, height: 38)
            .background(Color.modaX(2).opacity(0.13))
            .cornerRadius(10)
    }
}
