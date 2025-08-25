import UIKit

// MARK: - UIColor 扩展

extension UIColor {
    
    /// 通过16进制字符串创建颜色
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// 随机颜色
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
    
    /// 主题颜色
    static var primary: UIColor { return UIColor(hex: "#007AFF") }
    static var secondary: UIColor { return UIColor(hex: "#5856D6") }
    static var success: UIColor { return UIColor(hex: "#34C759") }
    static var warning: UIColor { return UIColor(hex: "#FF9500") }
    static var danger: UIColor { return UIColor(hex: "#FF3B30") }
    
    /// 背景颜色
    static var background: UIColor { return UIColor.systemBackground }
    static var secondaryBackground: UIColor { return UIColor.secondarySystemBackground }
    static var tertiaryBackground: UIColor { return UIColor.tertiarySystemBackground }
    
    /// 文本颜色
    static var primaryText: UIColor { return UIColor.label }
    static var secondaryText: UIColor { return UIColor.secondaryLabel }
    static var tertiaryText: UIColor { return UIColor.tertiaryLabel }
    
    /// 将颜色转换为16进制字符串
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = (Int(red * 255) << 16) | (Int(green * 255) << 8) | Int(blue * 255)
        return String(format: "#%06x", rgb)
    }
}