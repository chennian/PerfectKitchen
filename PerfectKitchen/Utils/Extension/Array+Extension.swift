import Foundation

// MARK: - Array 扩展

extension Array {
    
    // MARK: - 安全访问
    
    /// 安全获取元素，避免越界
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// 安全获取多个元素
    subscript(safe range: Range<Int>) -> ArraySlice<Element>? {
        guard range.lowerBound >= 0, range.upperBound <= count else { return nil }
        return self[range]
    }
    
    // MARK: - 元素操作
    
    /// 移除第一个匹配的元素
    mutating func removeFirst(where predicate: (Element) -> Bool) {
        guard let index = firstIndex(where: predicate) else { return }
        remove(at: index)
    }
    
    /// 移除所有匹配的元素
    mutating func removeAll(where predicate: (Element) -> Bool) {
        removeAll(where: predicate)
    }
    
    /// 去重（保持顺序）
    func unique() -> [Element] where Element: Hashable {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
    
    /// 去重（根据某个属性）
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
    
    /// 分组（根据某个属性）
    func grouped<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] {
        return Dictionary(grouping: self, by: { $0[keyPath: keyPath] })
    }
    
    // MARK: - 分页相关
    
    /// 分页
    func paginated(page: Int, pageSize: Int) -> [Element] {
        let startIndex = page * pageSize
        let endIndex = Swift.min(startIndex + pageSize, count)
        
        guard startIndex < endIndex else { return [] }
        return Array(self[startIndex..<endIndex])
    }
    
    /// 获取总页数
    func totalPages(pageSize: Int) -> Int {
        guard pageSize > 0 else { return 0 }
        return Int(ceil(Double(count) / Double(pageSize)))
    }
    
    // MARK: - 随机操作
    
    /// 随机打乱数组
    mutating func shuffle() {
        guard count > 1 else { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            if i != j {
                swapAt(i, j)
            }
        }
    }
    
    /// 返回随机打乱的数组
    func shuffled() -> [Element] {
        var array = self
        array.shuffle()
        return array
    }
    
    /// 随机获取一个元素
    func randomElement() -> Element? {
        guard !isEmpty else { return nil }
        return self[Int(arc4random_uniform(UInt32(count)))]
    }
    
    // MARK: - 转换操作
    
    /// 将数组转换为字典
    func toDictionary<Key: Hashable>(keyPath: KeyPath<Element, Key>) -> [Key: Element] {
        return reduce(into: [:]) { result, element in
            result[element[keyPath: keyPath]] = element
        }
    }
    
    /// 将数组转换为字典（多个元素对应同一个key）
    func toDictionaryOfArrays<Key: Hashable>(keyPath: KeyPath<Element, Key>) -> [Key: [Element]] {
        return reduce(into: [:]) { result, element in
            let key = element[keyPath: keyPath]
            result[key, default: []].append(element)
        }
    }
    
    // MARK: - 实用方法
    
    /// 判断数组是否包含某个索引
    func contains(index: Int) -> Bool {
        return index >= 0 && index < count
    }
    
    /// 交换两个元素的位置
    mutating func swap(_ firstIndex: Int, _ secondIndex: Int) {
        guard contains(index: firstIndex), contains(index: secondIndex) else { return }
        swapAt(firstIndex, secondIndex)
    }
    
    /// 在指定位置插入元素
    mutating func insert(_ element: Element, atSafe index: Int) {
        let safeIndex = Swift.max(0, Swift.min(index, count))
        insert(element, at: safeIndex)
    }
    
    /// 批量添加元素
    mutating func append(contentsOf elements: [Element]) {
        append(contentsOf: elements)
    }
}

// MARK: - 可选数组扩展

extension Array where Element: OptionalType {
    
    /// 过滤掉nil值
    func compact() -> [Element.Wrapped] {
        return compactMap { $0.value }
    }
}

protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    var value: Wrapped? { return self }
}
