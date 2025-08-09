import Foundation
import Moya
import Combine
import UIKit

// MARK: - 网络管理器
class NetworkManager {
    
    // MARK: - 单例
    static let shared = NetworkManager()
    
    // MARK: - 属性
    private let provider: MoyaProvider<NetworkAPI>
    private let decoder = JSONDecoder.apiDecoder
    private let encoder = JSONEncoder.apiEncoder
    
    // MARK: - 初始化
    private init() {
        // 配置网络日志插件
        let loggerPlugin = NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(
            formatter: .init(responseData: JSONResponseDataFormatter),
            logOptions: [.requestBody, .successResponseBody, .errorResponseBody, .verbose]
        ))
        
        // 创建自定义网络活动插件
        let networkActivityPlugin = NetworkActivityIndicatorPlugin()
        
        // 创建 Provider
        self.provider = MoyaProvider<NetworkAPI>(
            plugins: [loggerPlugin, networkActivityPlugin]
        )
    }
    
    // MARK: - 通用请求方法（回调版本）
    
    /// 执行网络请求
    func request<T: Codable>(
        _ target: NetworkAPI,
        type: T.Type,
        completion: @escaping NetworkCompletion<T>
    ) {
        provider.request(target) { result in
            switch result {
            case .success(let response):
                let networkResult = Result<T, NetworkError>.fromMoyaResponse(response, type: type, decoder: self.decoder)
                completion(networkResult)
                
                // 处理错误
                if case .failure(let error) = networkResult {
                    NetworkErrorHandler.showError(error)
                }
                
            case .failure(let moyaError):
                let networkError = NetworkErrorHandler.handleMoyaError(moyaError)
                completion(.failure(networkError))
                NetworkErrorHandler.showError(networkError)
            }
        }
    }
    
    /// 执行不需要返回数据的请求
    func request(
        _ target: NetworkAPI,
        completion: @escaping NetworkCompletion<EmptyResponse>
    ) {
        provider.request(target) { result in
            switch result {
            case .success(let response):
                let networkResult = Result<EmptyResponse, NetworkError>.fromMoyaEmptyResponse(response)
                completion(networkResult)
                
                // 处理错误
                if case .failure(let error) = networkResult {
                    NetworkErrorHandler.showError(error)
                }
                
            case .failure(let moyaError):
                let networkError = NetworkErrorHandler.handleMoyaError(moyaError)
                completion(.failure(networkError))
                NetworkErrorHandler.showError(networkError)
            }
        }
    }
    
    // MARK: - Combine 支持
    
    /// 使用 Combine 执行网络请求
    @available(iOS 13.0, *)
    func request<T: Codable>(_ target: NetworkAPI, type: T.Type) -> AnyPublisher<T, NetworkError> {
        return provider.requestPublisher(target)
            .tryMap { response in
                switch Result<T, NetworkError>.fromMoyaResponse(response, type: type, decoder: self.decoder) {
                case .success(let data):
                    return data
                case .failure(let error):
                    throw error
                }
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let moyaError = error as? MoyaError {
                    return NetworkErrorHandler.handleMoyaError(moyaError)
                } else {
                    return NetworkError.unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// 使用 Combine 执行不需要返回数据的请求
    @available(iOS 13.0, *)
    func request(_ target: NetworkAPI) -> AnyPublisher<EmptyResponse, NetworkError> {
        return provider.requestPublisher(target)
            .tryMap { response in
                switch Result<EmptyResponse, NetworkError>.fromMoyaEmptyResponse(response) {
                case .success(let data):
                    return data
                case .failure(let error):
                    throw error
                }
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let moyaError = error as? MoyaError {
                    return NetworkErrorHandler.handleMoyaError(moyaError)
                } else {
                    return NetworkError.unknown(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - async/await 支持
    
    /// 使用 async/await 执行网络请求
    @available(iOS 13.0, *)
    func request<T: Codable>(_ target: NetworkAPI, type: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            request(target, type: type) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// 使用 async/await 执行不需要返回数据的请求
    @available(iOS 13.0, *)
    func request(_ target: NetworkAPI) async throws -> EmptyResponse {
        return try await withCheckedThrowingContinuation { continuation in
            request(target) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - 文件上传
    
    /// 上传图片
    func uploadImage(
        imageData: Data,
        fileName: String = "image.jpg",
        completion: @escaping NetworkCompletion<UploadResponse>
    ) {
        let target = NetworkAPI.uploadImage(imageData: imageData, fileName: fileName)
        request(target, type: UploadResponse.self, completion: completion)
    }
    
    /// 上传文件
    func uploadFile(
        fileData: Data,
        fileName: String,
        completion: @escaping NetworkCompletion<UploadResponse>
    ) {
        let target = NetworkAPI.uploadFile(fileData: fileData, fileName: fileName)
        request(target, type: UploadResponse.self, completion: completion)
    }
    
    // MARK: - 便利方法
    
    /// 检查网络连接状态
    func isNetworkReachable() -> Bool {
        // 这里可以集成网络可达性检测库
        // 例如使用 Alamofire 的 NetworkReachabilityManager
        return true
    }
    
    /// 取消所有请求
    func cancelAllRequests() {
        // Moya 没有直接的取消所有请求方法
        // 可以通过其他方式实现，例如使用 Cancellable 数组
    }
}

// MARK: - 扩展：Moya Combine 支持
extension MoyaProvider {
    @available(iOS 13.0, *)
    func requestPublisher(_ target: Target) -> AnyPublisher<Response, MoyaError> {
        return Future { promise in
            self.request(target) { result in
                promise(result)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - JSON 格式化器（用于日志）
private func JSONResponseDataFormatter(_ data: Data) -> String {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? ""
    } catch {
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - 网络配置
struct NetworkConfiguration {
    static let timeout: TimeInterval = 30.0
    static let retryCount = 3
    static let cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
}

// MARK: - 自定义网络活动指示器插件
class NetworkActivityIndicatorPlugin: PluginType {
    
    func willSend(_ request: RequestType, target: TargetType) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
    
    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
}

// MARK: - 请求拦截器（可选）
class NetworkRequestInterceptor {
    
    /// 请求前拦截
    static func interceptRequest(_ target: NetworkAPI) -> NetworkAPI {
        // 可以在这里添加通用的请求参数、头部等
        return target
    }
    
    /// 响应后拦截
    static func interceptResponse<T>(_ result: NetworkResult<T>) -> NetworkResult<T> {
        // 可以在这里处理通用的响应逻辑
        return result
    }
} 