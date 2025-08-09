import Foundation
import Moya

// MARK: - 网络API端点定义
enum NetworkAPI {
    // 用户相关API
    case login(email: String, password: String)
    case register(email: String, password: String, name: String)
    case getUserInfo(userId: String)
    case updateUserInfo(userId: String, userData: [String: Any])
    
    // 数据相关API
    case fetchDataList(page: Int, limit: Int)
    case fetchDataDetail(id: String)
    case uploadData(data: [String: Any])
    case deleteData(id: String)
    
    // 文件上传
    case uploadImage(imageData: Data, fileName: String)
    case uploadFile(fileData: Data, fileName: String)
}

// MARK: - TargetType 协议实现
extension NetworkAPI: TargetType {
    
    /// 基础URL
    var baseURL: URL {
        return URL(string: "https://api.example.com")!
    }
    
    /// API路径
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .getUserInfo(let userId):
            return "/users/\(userId)"
        case .updateUserInfo(let userId, _):
            return "/users/\(userId)"
        case .fetchDataList:
            return "/data"
        case .fetchDataDetail(let id):
            return "/data/\(id)"
        case .uploadData:
            return "/data"
        case .deleteData(let id):
            return "/data/\(id)"
        case .uploadImage:
            return "/upload/image"
        case .uploadFile:
            return "/upload/file"
        }
    }
    
    /// HTTP请求方法
    var method: Moya.Method {
        switch self {
        case .login, .register, .uploadData, .uploadImage, .uploadFile:
            return .post
        case .getUserInfo, .fetchDataList, .fetchDataDetail:
            return .get
        case .updateUserInfo:
            return .put
        case .deleteData:
            return .delete
        }
    }
    
    /// 请求任务
    var task: Task {
        switch self {
        case .login(let email, let password):
            let parameters = ["email": email, "password": password]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .register(let email, let password, let name):
            let parameters = ["email": email, "password": password, "name": name]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .getUserInfo, .fetchDataDetail, .deleteData:
            return .requestPlain
            
        case .updateUserInfo(_, let userData):
            return .requestParameters(parameters: userData, encoding: JSONEncoding.default)
            
        case .fetchDataList(let page, let limit):
            let parameters = ["page": page, "limit": limit]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
            
        case .uploadData(let data):
            return .requestParameters(parameters: data, encoding: JSONEncoding.default)
            
        case .uploadImage(let imageData, let fileName):
            let formData = MultipartFormData(provider: .data(imageData), name: "image", fileName: fileName, mimeType: "image/jpeg")
            return .uploadMultipart([formData])
            
        case .uploadFile(let fileData, let fileName):
            let formData = MultipartFormData(provider: .data(fileData), name: "file", fileName: fileName)
            return .uploadMultipart([formData])
        }
    }
    
    /// 请求头
    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        // 添加认证token（如果存在）
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // 文件上传时的特殊处理
        switch self {
        case .uploadImage, .uploadFile:
            headers["Content-Type"] = "multipart/form-data"
        default:
            break
        }
        
        return headers
    }
    
    /// 验证类型
    var validationType: ValidationType {
        return .successCodes
    }
    
    /// 示例数据（用于测试）
    var sampleData: Data {
        switch self {
        case .login, .register:
            return """
            {
                "success": true,
                "data": {
                    "token": "sample_token",
                    "user": {
                        "id": "123",
                        "email": "test@example.com",
                        "name": "Test User"
                    }
                }
            }
            """.data(using: .utf8)!
            
        case .getUserInfo:
            return """
            {
                "success": true,
                "data": {
                    "id": "123",
                    "email": "test@example.com",
                    "name": "Test User"
                }
            }
            """.data(using: .utf8)!
            
        case .fetchDataList:
            return """
            {
                "success": true,
                "data": {
                    "items": [],
                    "total": 0,
                    "page": 1,
                    "limit": 10
                }
            }
            """.data(using: .utf8)!
            
        default:
            return """
            {
                "success": true,
                "message": "操作成功"
            }
            """.data(using: .utf8)!
        }
    }
} 