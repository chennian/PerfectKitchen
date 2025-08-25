import Foundation

// MARK: - Date 扩展

extension Date {
    
    // MARK: - 日期格式化
    
    /// 格式化日期字符串
    func string(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
    
    /// 相对时间描述（如：刚刚、2分钟前、3小时前等）
    var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        }
        
        if let month = components.month, month > 0 {
            return "\(month)个月前"
        }
        
        if let day = components.day, day > 0 {
            return day == 1 ? "昨天" : "\(day)天前"
        }
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        }
        
        if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        }
        
        if let second = components.second, second > 0 {
            return "\(second)秒前"
        }
        
        return "刚刚"
    }
    
    // MARK: - 日期计算
    
    /// 添加时间间隔
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }
    
    /// 获取日期的开始时间（00:00:00）
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// 获取日期的结束时间（23:59:59）
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
    
    /// 获取星期几（1-7，周日为1）
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    /// 获取星期几的中文描述
    var weekdayString: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[weekday - 1]
    }
    
    // MARK: - 日期比较
    
    /// 判断是否是今天
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// 判断是否是昨天
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// 判断是否是明天
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    /// 判断是否是周末
    var isWeekend: Bool {
        return Calendar.current.isDateInWeekend(self)
    }
    
    /// 比较两个日期是否在同一天
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// 获取年龄
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
    
    // MARK: - 时间戳
    
    /// 获取时间戳（秒）
    var timestamp: TimeInterval {
        return timeIntervalSince1970
    }
    
    /// 获取时间戳（毫秒）
    var timestampMilliseconds: Int64 {
        return Int64(timeIntervalSince1970 * 1000)
    }
    
    /// 从时间戳创建日期
    static func fromTimestamp(_ timestamp: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// 从毫秒时间戳创建日期
    static func fromMilliseconds(_ milliseconds: Int64) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}