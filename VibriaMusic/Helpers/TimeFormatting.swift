import Foundation

/// Formats a `Double` representing a time interval (in seconds)
/// into a human-readable string.
///
/// Output format:
/// - `HH:mm:ss` when duration is 1 hour or longer
/// - `mm:ss` when duration is less than 1 hour
///
/// Examples:
/// - `65.0.hmsString` → `"01:05"`
/// - `3661.0.hmsString` → `"1:01:01"`
extension Double {

    /// Time formatted as hours, minutes and seconds.
    var hmsString: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
