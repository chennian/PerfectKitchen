import Foundation

// MARK: - 通用响应模型
struct NetworkResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let code: Int?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case code
    }
}

// MARK: - 分页响应模型
struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case limit
        case hasMore = "has_more"
    }
}

// MARK: - 用户相关模型
struct User: Codable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatar
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LoginResponse: Codable {
    let token: String
    let user: User
    let refreshToken: String?
    let expiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case token
        case user
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - 文件上传响应模型
struct UploadResponse: Codable {
    let url: String
    let filename: String
    let size: Int
    let mimeType: String?
    
    enum CodingKeys: String, CodingKey {
        case url
        case filename
        case size
        case mimeType = "mime_type"
    }
}

// MARK: - 通用数据项模型
struct DataItem: Codable {
    let id: String
    let title: String
    let description: String?
    let createdAt: String
    let updatedAt: String?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case status
    }
}

// MARK: - 请求参数模型
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct UpdateUserRequest: Codable {
    let name: String?
    let avatar: String?
}

// MARK: - 扩展：空响应模型
struct EmptyResponse: Codable {
    // 用于只关心成功状态的请求
}

// MARK: - 扩展：Encodable 到字典转换
extension Encodable {
    /// 将 Encodable 对象转换为字典
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

// MARK: - 扩展：字典到 Decodable 转换
extension Decodable {
    /// 从字典创建 Decodable 对象
    static func fromDictionary(_ dictionary: [String: Any]) -> Self? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

// MARK: - 日期格式化器
extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}

extension JSONEncoder {
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }
} 