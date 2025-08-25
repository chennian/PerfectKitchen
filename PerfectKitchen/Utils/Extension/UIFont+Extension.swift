import UIKit

// MARK: - UIFont 扩展

extension UIFont {
    
    /// 系统字体快捷方式
    static func regular(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
    
    static func medium(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    static func semibold(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    
    static func bold(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .bold)
    }
    
    static func heavy(size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .heavy)
    }
    
    /// 预设字体大小
    static var largeTitle: UIFont { return UIFont.preferredFont(forTextStyle: .largeTitle) }
    static var title1: UIFont { return UIFont.preferredFont(forTextStyle: .title1) }
    static var title2: UIFont { return UIFont.preferredFont(forTextStyle: .title2) }
    static var title3: UIFont { return UIFont.preferredFont(forTextStyle: .title3) }
    static var headline: UIFont { return UIFont.preferredFont(forTextStyle: .headline) }
    static var subheadline: UIFont { return UIFont.preferredFont(forTextStyle: .subheadline) }
    static var body: UIFont { return UIFont.preferredFont(forTextStyle: .body) }
    static var callout: UIFont { return UIFont.preferredFont(forTextStyle: .callout) }
    static var footnote: UIFont { return UIFont.preferredFont(forTextStyle: .footnote) }
    static var caption1: UIFont { return UIFont.preferredFont(forTextStyle: .caption1) }
    static var caption2: UIFont { return UIFont.preferredFont(forTextStyle: .caption2) }
    
    /// 动态字体支持
    static func dynamicFont(forTextStyle style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: descriptor.pointSize, weight: weight)
        return metrics.scaledFont(for: font)
    }
}