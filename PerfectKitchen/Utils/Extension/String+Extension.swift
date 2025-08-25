import Foundation
import UIKit

// MARK: - String 扩展

extension String {
    
    // MARK: - 字符串处理
    
    /// 去除首尾空格和换行符
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 判断字符串是否为空或仅包含空白字符
    var isBlank: Bool {
        return trimmed.isEmpty
    }
    
    /// 判断字符串是否包含中文
    var containsChinese: Bool {
        return range(of: "\\p{Han}", options: .regularExpression) != nil
    }
    
    /// 获取字符串的拼音
    var pinyin: String {
        let mutableString = NSMutableString(string: self)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        return String(mutableString).replacingOccurrences(of: " '", with: "")
    }
    
    /// 获取字符串的首字母
    var firstLetter: String {
        guard !isEmpty else { return "" }
        let pinyin = self.pinyin
        return String(pinyin.prefix(1)).uppercased()
    }
    
    /// 截取字符串
    func substring(from index: Int) -> String {
        guard index < count else { return "" }
        let startIndex = self.index(self.startIndex, offsetBy: index)
        return String(self[startIndex...])
    }
    
    func substring(to index: Int) -> String {
        guard index <= count, index >= 0 else { return "" }
        let endIndex = self.index(self.startIndex, offsetBy: index)
        return String(self[..<endIndex])
    }
    
    func substring(with range: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    // MARK: - 正则表达式
    
    /// 判断是否是邮箱
    var isEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return matches(pattern: emailRegex)
    }
    
    /// 判断是否是手机号
    var isPhoneNumber: Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        return matches(pattern: phoneRegex)
    }
    
    /// 判断是否是身份证号
    var isIDCard: Bool {
        let idCardRegex = "(^\\d{15}$)|(^\\d{18}$)|(^\\d{17}(\\d|X|x)$)"
        return matches(pattern: idCardRegex)
    }
    
    /// 正则匹配
    func matches(pattern: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }
    
    /// 提取匹配的字符串
    func extract(pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let results = regex.matches(in: self, range: NSRange(startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            return []
        }
    }
    
    // MARK: - 编码解码
    
    /// URL编码
    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    /// URL解码
    var urlDecoded: String? {
        return removingPercentEncoding
    }
    
    /// Base64编码
    var base64Encoded: String? {
        return data(using: .utf8)?.base64EncodedString()
    }
    
    /// Base64解码
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - 尺寸计算
    
    /// 计算文本尺寸
    func size(with font: UIFont, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, 
                                          options: .usesLineFragmentOrigin, 
                                          attributes: [.font: font], 
                                          context: nil)
        return CGSize(width: ceil(boundingBox.width), height: ceil(boundingBox.height))
    }
    
    /// 计算文本高度
    func height(with font: UIFont, width: CGFloat) -> CGFloat {
        return size(with: font, maxWidth: width).height
    }
    
    /// 计算文本宽度
    func width(with font: UIFont) -> CGFloat {
        return size(with: font).width
    }
    
    // MARK: - 本地化
    
    /// 本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
    
    // MARK: - JSON处理
    
    /// 将JSON字符串转换为字典
    var toDictionary: [String: Any]? {
        guard let data = data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    /// 将JSON字符串转换为数组
    var toArray: [Any]? {
        guard let data = data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [Any]
    }
    
    /// 将字典或数组转换为JSON字符串
    static func fromJSON(_ object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}