import Foundation

extension Date {
    /// "2 min ago" style relative formatting for list rows.
    var relative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
