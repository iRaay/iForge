import SwiftUI

enum iForgeFont {
    static func custom(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("CairoPlay-\(weight.fileName)", size: size)
    }
}

private extension Font.Weight {
    var fileName: String {
        switch self {
        case .black: return "Black"
        case .heavy: return "ExtraBold"
        case .bold: return "Bold"
        case .semibold: return "SemiBold"
        case .medium: return "Medium"
        case .light: return "Light"
        case .ultraLight: return "ExtraLight"
        default: return "Regular"
        }
    }
}

struct iForgeFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(iForgeFont.custom(size: UIFont.labelFontSize))
    }
}

extension View {
    func iForgeTypography() -> some View { modifier(iForgeFontModifier()) }
}
