import Foundation

// MARK: - Dictionary 扩展

extension Dictionary {
    
    // MARK: - 合并操作
    
    /// 合并另一个字典
    mutating func merge(_ other: [Key: Value]) {
        merge(other) { (current, _) in current }
    }
    
    /// 返回合并后的新字典
    func merging(_ other: [Key: Value]) -> [Key: Value] {
        return merging(other) { (current, _) in current }
    }
    
    // MARK: - 转换操作
    
    /// 转换为查询字符串
    var queryString: String {
        return map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
    }
    
    /// 转换为JSON字符串
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// 映射值
    func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> [Key: T] {
        return try reduce(into: [Key: T]()) { result, element in
            result[element.key] = try transform(element.value)
        }
    }
    
    /// 紧凑映射值（过滤nil）
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        return try reduce(into: [Key: T]()) { result, element in
            if let transformed = try transform(element.value) {
                result[element.key] = transformed
            }
        }
    }
    
    // MARK: - 安全访问
    
    /// 安全获取值，并转换为指定类型
    func value<T>(forKey key: Key, as type: T.Type) -> T? {
        guard let value = self[key] else { return nil }
        return value as? T
    }
    
    /// 安全获取字符串值
    func string(forKey key: Key) -> String? {
        return value(forKey: key, as: String.self)
    }
    
    /// 安全获取整数值
    func int(forKey key: Key) -> Int? {
        if let intValue = value(forKey: key, as: Int.self) {
            return intValue
        }
        if let stringValue = string(forKey: key) {
            return Int(stringValue)
        }
        return nil
    }
    
    /// 安全获取浮点数值
    func double(forKey key: Key) -> Double? {
        if let doubleValue = value(forKey: key, as: Double.self) {
            return doubleValue
        }
        if let stringValue = string(forKey: key) {
            return Double(stringValue)
        }
        return nil
    }
    
    /// 安全获取布尔值
    func bool(forKey key: Key) -> Bool? {
        if let boolValue = value(forKey: key, as: Bool.self) {
            return boolValue
        }
        if let intValue = int(forKey: key) {
            return intValue != 0
        }
        if let stringValue = string(forKey: key)?.lowercased() {
            return ["true", "yes", "1"].contains(stringValue)
        }
        return nil
    }
    
    // MARK: - 实用方法
    
    /// 检查是否包含某个键
    func hasKey(_ key: Key) -> Bool {
        return self[key] != nil
    }
    
    /// 获取所有键的数组
    var allKeys: [Key] {
        return Array(keys)
    }
    
    /// 获取所有值的数组
    var allValues: [Value] {
        return Array(values)
    }
    
    /// 过滤字典
    func filter(_ isIncluded: (Key, Value) throws -> Bool) rethrows -> [Key: Value] {
        return try filter(isIncluded)
    }
    
    /// 映射键
    func mapKeys<T: Hashable>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        return try reduce(into: [T: Value]()) { result, element in
            let newKey = try transform(element.key)
            result[newKey] = element.value
        }
    }
}

// MARK: - JSON字典扩展

extension Dictionary where Key == String {
    
    /// 从JSON文件加载字典
    static func fromJSONFile(named filename: String) -> [String: Any]? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            return nil
        }
    }
    
    /// 将字典保存为JSON文件
    func saveAsJSONFile(named filename: String) -> Bool {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(filename).json")
        
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            try data.write(to: fileURL)
            return true
        } catch {
            return false
        }
    }
}