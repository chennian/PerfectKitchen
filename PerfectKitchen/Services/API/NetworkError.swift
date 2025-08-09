import Foundation
import Moya

// MARK: - 网络错误类型
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case moyaError(MoyaError)
    case serverError(Int, String?)
    case networkUnavailable
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL地址"
        case .noData:
            return "服务器未返回数据"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .encodingError(let error):
            return "数据编码失败: \(error.localizedDescription)"
        case .moyaError(let moyaError):
            return moyaError.localizedDescription
        case .serverError(let code, let message):
            return "服务器错误(\(code)): \(message ?? "未知错误")"
        case .networkUnavailable:
            return "网络连接不可用"
        case .timeout:
            return "请求超时"
        case .unauthorized:
            return "用户认证失败"
        case .forbidden:
            return "访问被拒绝"
        case .notFound:
            return "请求的资源不存在"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .invalidURL:
            return -1001
        case .noData:
            return -1002
        case .decodingError:
            return -1003
        case .encodingError:
            return -1004
        case .moyaError(let moyaError):
            return moyaError.errorCode
        case .serverError(let code, _):
            return code
        case .networkUnavailable:
            return -1009
        case .timeout:
            return -1001
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .unknown:
            return -1
        }
    }
}

// MARK: - 错误处理工具
struct NetworkErrorHandler {
    
    /// 处理 Moya 错误
    static func handleMoyaError(_ error: MoyaError) -> NetworkError {
        switch error {
        case .imageMapping, .jsonMapping, .stringMapping, .objectMapping:
            return .decodingError(error)
        case .encodableMapping:
            return .encodingError(error)
        case .statusCode(let response):
            return handleHTTPStatusCode(response.statusCode, data: response.data)
        case .underlying(let nsError, _):
            return handleUnderlyingError(nsError)
        case .requestMapping:
            return .invalidURL
        case .parameterEncoding:
            return .encodingError(error)
        }
    }
    
    /// 处理 HTTP 状态码
    static func handleHTTPStatusCode(_ statusCode: Int, data: Data?) -> NetworkError {
        var message: String? = nil
        
        // 尝试从响应数据中提取错误信息
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorMessage = json["message"] as? String {
            message = errorMessage
        }
        
        switch statusCode {
        case 400:
            return .serverError(statusCode, message ?? "请求参数错误")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 422:
            return .serverError(statusCode, message ?? "请求参数验证失败")
        case 500...599:
            return .serverError(statusCode, message ?? "服务器内部错误")
        default:
            return .serverError(statusCode, message)
        }
    }
    
    /// 处理底层网络错误
    static func handleUnderlyingError(_ error: Error) -> NetworkError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost:
            return .networkUnavailable
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorBadURL,
             NSURLErrorUnsupportedURL:
            return .invalidURL
        default:
            return .unknown(error)
        }
    }
    
    /// 显示错误信息
    static func showError(_ error: NetworkError) {
        DispatchQueue.main.async {
            // 这里可以集成具体的错误显示逻辑
            // 例如显示 Toast、Alert 等
            print("网络错误: \(error.localizedDescription)")
            
            // 可以根据错误类型执行特定操作
            switch error {
            case .unauthorized:
                // 处理用户认证失败，例如跳转到登录页面
                handleUnauthorizedError()
            case .networkUnavailable:
                // 处理网络不可用
                handleNetworkUnavailable()
            default:
                break
            }
        }
    }
    
    /// 处理认证失败
    private static func handleUnauthorizedError() {
        // 清除本地保存的认证信息
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        
        // 发送通知或执行其他操作
        NotificationCenter.default.post(name: .userNeedsReauth, object: nil)
    }
    
    /// 处理网络不可用
    private static func handleNetworkUnavailable() {
        // 可以显示网络不可用的提示
        // 或者启用离线模式等
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let userNeedsReauth = Notification.Name("userNeedsReauth")
    static let networkUnavailable = Notification.Name("networkUnavailable")
}

// MARK: - 结果类型别名
typealias NetworkResult<T> = Result<T, NetworkError>
typealias NetworkCompletion<T> = (NetworkResult<T>) -> Void

// MARK: - 扩展：处理响应结果
extension Result where Success: Codable, Failure == NetworkError {
    
    /// 从 Moya 响应创建结果
    static func fromMoyaResponse<T: Codable>(
        _ response: Response,
        type: T.Type,
        decoder: JSONDecoder = .apiDecoder
    ) -> Result<T, NetworkError> {
        
        do {
            // 首先尝试解析为通用响应格式
            let networkResponse = try decoder.decode(NetworkResponse<T>.self, from: response.data)
            
            if networkResponse.success, let data = networkResponse.data {
                return .success(data)
            } else {
                let message = networkResponse.message ?? "请求失败"
                let code = networkResponse.code ?? response.statusCode
                return .failure(.serverError(code, message))
            }
        } catch {
            // 如果通用响应格式解析失败，尝试直接解析目标类型
            do {
                let data = try decoder.decode(T.self, from: response.data)
                return .success(data)
            } catch {
                return .failure(.decodingError(error))
            }
        }
    }
    
    /// 从 Moya 响应创建空结果
    static func fromMoyaEmptyResponse(_ response: Response) -> Result<EmptyResponse, NetworkError> {
        // 对于空响应，只要状态码正确就认为成功
        if 200...299 ~= response.statusCode {
            return .success(EmptyResponse())
        } else {
            return .failure(NetworkErrorHandler.handleHTTPStatusCode(response.statusCode, data: response.data))
        }
    }
} 