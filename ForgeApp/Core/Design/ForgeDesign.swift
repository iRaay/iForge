import SwiftUI

/// Central SF Symbol catalog. Keeping symbols here prevents inconsistent or
/// outdated icon choices across feature screens.
enum ForgeSymbol {
    static let home = "rectangle.grid.2x2.fill"
    static let projects = "square.stack.3d.up.fill"
    static let builds = "hammer.circle.fill"
    static let ipa = "shippingbox.fill"
    static let settings = "slider.horizontal.3"

    static let add = "plus"
    static let github = "chevron.left.forwardslash.chevron.right"
    static let git = "arrow.triangle.branch"
    static let upload = "arrow.up.doc.fill"
    static let download = "arrow.down.doc.fill"
    static let share = "square.and.arrow.up"
    static let play = "play.fill"
    static let refresh = "arrow.clockwise"
    static let search = "magnifyingglass"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.octagon.fill"
    static let success = "checkmark.seal.fill"
    static let info = "info.circle.fill"
    static let queue = "list.bullet.clipboard.fill"
    static let pipeline = "point.3.connected.trianglepath.dotted"
    static let branch = "arrow.triangle.branch"
    static let code = "curlybraces.square.fill"
    static let theme = "circle.lefthalf.filled"
    static let language = "character.book.closed.fill"
    static let notification = "bell.badge.fill"
    static let storage = "internaldrive.fill"
    static let privacy = "lock.shield.fill"
}

struct ForgeDesign {
    static let accent = Color(red: 0.39, green: 0.29, blue: 0.88)
    static let accentSecondary = Color(red: 0.25, green: 0.53, blue: 0.98)
    static let success = Color(red: 0.12, green: 0.65, blue: 0.43)
    static let warning = Color(red: 0.88, green: 0.57, blue: 0.12)
    static let danger = Color(red: 0.84, green: 0.22, blue: 0.32)

    static let cardRadius: CGFloat = 20
    static let controlRadius: CGFloat = 14
    static let pagePadding: CGFloat = 18
}

struct ForgeCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ForgeDesign.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ForgeDesign.cardRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
            }
    }
}

extension View {
    func forgeCard() -> some View { modifier(ForgeCardModifier()) }

    func forgePagePadding() -> some View {
        padding(.horizontal, ForgeDesign.pagePadding)
    }
}

struct ForgeStatusBadge: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.13), in: Capsule())
    }
}

struct ForgeEmptyState: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(ForgeDesign.accent)
    }
}
