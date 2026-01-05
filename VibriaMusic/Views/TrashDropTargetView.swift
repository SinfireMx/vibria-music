import SwiftUI
import UniformTypeIdentifiers

/// Trash icon used as a drag & drop target.
/// Designed to accept dropped songs and trigger a delete action.
///
/// Usage:
/// - Bind `isTargeted` to visually react when a drag enters the drop area
/// - Provide `onSongDropped` to handle deletion logic
struct TrashDropTargetView: View {

    /// Indicates whether a draggable item is currently hovering over the target
    @Binding var isTargeted: Bool

    /// Callback executed when a song is successfully dropped on the trash icon
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
            .onDrop(
                of: [UTType.text],
                isTargeted: $isTargeted
            ) { _ in
                // Notify parent that a song was dropped
                onSongDropped()
                return true
            }
            .animation(.easeInOut(duration: 0.17), value: isTargeted)
    }
}
