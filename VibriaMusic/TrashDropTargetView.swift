import SwiftUI
import UniformTypeIdentifiers


// --- Kosz jako drop target ---
struct TrashDropTargetView: View {
    @Binding var isTargeted: Bool
    var onSongDropped: () -> Void

    var body: some View {
        Image(systemName: "trash.circle.fill")
            .resizable()
            .frame(width: 64, height: 64)
            .foregroundColor(isTargeted ? .red : .gray.opacity(0.80))
            .background(
                Circle()
                    .fill(isTargeted ? Color.red.opacity(0.15) : Color.clear)
                    .scaleEffect(isTargeted ? 1.08 : 1.0)
            )
            .shadow(radius: isTargeted ? 12 : 5)
            .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
                onSongDropped()
                return true
            }
            .animation(.easeInOut(duration: 0.17), value: isTargeted)
    }
}
