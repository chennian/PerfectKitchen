import Foundation
import Combine
import UIKit

// MARK: - API服务类
class APIService {
    
    // MARK: - 单例
    static let shared = APIService()
    
    // MARK: - 属性
    private let networkManager = NetworkManager.shared
    
    // MARK: - 初始化
    private init() {}
    
    // MARK: - 认证相关API
    
    /// 用户登录
    func login(email: String, password: String, completion: @escaping NetworkCompletion<LoginResponse>) {
        let target = NetworkAPI.login(email: email, password: password)
        networkManager.request(target, type: LoginResponse.self) { result in
            // 登录成功后保存token
            if case .success(let loginResponse) = result {
                self.saveAuthToken(loginResponse.token)
                self.saveRefreshToken(loginResponse.refreshToken)
            }
            completion(result)
        }
    }
    
    /// 用户注册
    func register(email: String, password: String, name: String, completion: @escaping NetworkCompletion<LoginResponse>) {
        let target = NetworkAPI.register(email: email, password: password, name: name)
        networkManager.request(target, type: LoginResponse.self) { result in
            // 注册成功后保存token
            if case .success(let loginResponse) = result {
                self.saveAuthToken(loginResponse.token)
                self.saveRefreshToken(loginResponse.refreshToken)
            }
            completion(result)
        }
    }
    
    /// 用户登出
    func logout(completion: @escaping NetworkCompletion<EmptyResponse>) {
        // 清除本地保存的认证信息
        clearAuthToken()
        clearRefreshToken()
        
        // 可以调用服务器登出接口（如果有的话）
        completion(.success(EmptyResponse()))
    }
    
    // MARK: - 用户信息相关API
    
    /// 获取用户信息
    func getUserInfo(userId: String, completion: @escaping NetworkCompletion<User>) {
        let target = NetworkAPI.getUserInfo(userId: userId)
        networkManager.request(target, type: User.self, completion: completion)
    }
    
    /// 更新用户信息
    func updateUserInfo(userId: String, request: UpdateUserRequest, completion: @escaping NetworkCompletion<User>) {
        let userData = request.toDictionary() ?? [:]
        let target = NetworkAPI.updateUserInfo(userId: userId, userData: userData)
        networkManager.request(target, type: User.self, completion: completion)
    }
    
    // MARK: - 数据相关API
    
    /// 获取数据列表
    func fetchDataList(page: Int = 1, limit: Int = 20, completion: @escaping NetworkCompletion<PaginatedResponse<DataItem>>) {
        let target = NetworkAPI.fetchDataList(page: page, limit: limit)
        networkManager.request(target, type: PaginatedResponse<DataItem>.self, completion: completion)
    }
    
    /// 获取数据详情
    func fetchDataDetail(id: String, completion: @escaping NetworkCompletion<DataItem>) {
        let target = NetworkAPI.fetchDataDetail(id: id)
        networkManager.request(target, type: DataItem.self, completion: completion)
    }
    
    /// 上传数据
    func uploadData(data: [String: Any], completion: @escaping NetworkCompletion<DataItem>) {
        let target = NetworkAPI.uploadData(data: data)
        networkManager.request(target, type: DataItem.self, completion: completion)
    }
    
    /// 删除数据
    func deleteData(id: String, completion: @escaping NetworkCompletion<EmptyResponse>) {
        let target = NetworkAPI.deleteData(id: id)
        networkManager.request(target, completion: completion)
    }
    
    // MARK: - 文件上传API
    
    /// 上传图片
    func uploadImage(_ image: UIImage, compression: CGFloat = 0.8, completion: @escaping NetworkCompletion<UploadResponse>) {
        guard let imageData = image.jpegData(compressionQuality: compression) else {
            completion(.failure(.encodingError(NSError(domain: "ImageCompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片压缩失败"]))))
            return
        }
        
        let fileName = "image_\(Date().timeIntervalSince1970).jpg"
        networkManager.uploadImage(imageData: imageData, fileName: fileName, completion: completion)
    }
    
    /// 上传文件
    func uploadFile(fileURL: URL, completion: @escaping NetworkCompletion<UploadResponse>) {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            networkManager.uploadFile(fileData: fileData, fileName: fileName, completion: completion)
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Token管理
    
    private func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    private func saveRefreshToken(_ token: String?) {
        if let token = token {
            UserDefaults.standard.set(token, forKey: "refresh_token")
        }
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    private func clearRefreshToken() {
        UserDefaults.standard.removeObject(forKey: "refresh_token")
    }
    
    func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    func isLoggedIn() -> Bool {
        return getAuthToken() != nil
    }
}

// MARK: - Combine 扩展
@available(iOS 13.0, *)
extension APIService {
    
    /// 使用 Combine 登录
    func login(email: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let target = NetworkAPI.login(email: email, password: password)
        return networkManager.request(target, type: LoginResponse.self)
            .handleEvents(receiveOutput: { [weak self] loginResponse in
                self?.saveAuthToken(loginResponse.token)
                self?.saveRefreshToken(loginResponse.refreshToken)
            })
            .eraseToAnyPublisher()
    }
    
    /// 使用 Combine 注册
    func register(email: String, password: String, name: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let target = NetworkAPI.register(email: email, password: password, name: name)
        return networkManager.request(target, type: LoginResponse.self)
            .handleEvents(receiveOutput: { [weak self] loginResponse in
                self?.saveAuthToken(loginResponse.token)
                self?.saveRefreshToken(loginResponse.refreshToken)
            })
            .eraseToAnyPublisher()
    }
    
    /// 使用 Combine 获取用户信息
    func getUserInfo(userId: String) -> AnyPublisher<User, NetworkError> {
        let target = NetworkAPI.getUserInfo(userId: userId)
        return networkManager.request(target, type: User.self)
    }
    
    /// 使用 Combine 获取数据列表
    func fetchDataList(page: Int = 1, limit: Int = 20) -> AnyPublisher<PaginatedResponse<DataItem>, NetworkError> {
        let target = NetworkAPI.fetchDataList(page: page, limit: limit)
        return networkManager.request(target, type: PaginatedResponse<DataItem>.self)
    }
}

// MARK: - async/await 扩展
@available(iOS 13.0, *)
extension APIService {
    
    /// 使用 async/await 登录
    func login(email: String, password: String) async throws -> LoginResponse {
        let target = NetworkAPI.login(email: email, password: password)
        let loginResponse = try await networkManager.request(target, type: LoginResponse.self)
        
        // 保存token
        saveAuthToken(loginResponse.token)
        saveRefreshToken(loginResponse.refreshToken)
        
        return loginResponse
    }
    
    /// 使用 async/await 注册
    func register(email: String, password: String, name: String) async throws -> LoginResponse {
        let target = NetworkAPI.register(email: email, password: password, name: name)
        let loginResponse = try await networkManager.request(target, type: LoginResponse.self)
        
        // 保存token
        saveAuthToken(loginResponse.token)
        saveRefreshToken(loginResponse.refreshToken)
        
        return loginResponse
    }
    
    /// 使用 async/await 获取用户信息
    func getUserInfo(userId: String) async throws -> User {
        let target = NetworkAPI.getUserInfo(userId: userId)
        return try await networkManager.request(target, type: User.self)
    }
    
    /// 使用 async/await 获取数据列表
    func fetchDataList(page: Int = 1, limit: Int = 20) async throws -> PaginatedResponse<DataItem> {
        let target = NetworkAPI.fetchDataList(page: page, limit: limit)
        return try await networkManager.request(target, type: PaginatedResponse<DataItem>.self)
    }
    
    /// 使用 async/await 上传图片
    func uploadImage(_ image: UIImage, compression: CGFloat = 0.8) async throws -> UploadResponse {
        guard let imageData = image.jpegData(compressionQuality: compression) else {
            throw NetworkError.encodingError(NSError(domain: "ImageCompressionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片压缩失败"]))
        }
        
        let fileName = "image_\(Date().timeIntervalSince1970).jpg"
        let target = NetworkAPI.uploadImage(imageData: imageData, fileName: fileName)
        return try await networkManager.request(target, type: UploadResponse.self)
    }
}

// MARK: - 使用示例类
class APIUsageExample {
    
    private let apiService = APIService.shared
    
    // MARK: - 传统回调方式示例
    func loginExample() {
        apiService.login(email: "test@example.com", password: "password") { result in
            switch result {
            case .success(let loginResponse):
                print("登录成功: \(loginResponse.user.name)")
            case .failure(let error):
                print("登录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Combine 方式示例
    @available(iOS 13.0, *)
    func loginWithCombineExample() {
        var cancellables = Set<AnyCancellable>()
        
        apiService.login(email: "test@example.com", password: "password")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("登录失败: \(error.localizedDescription)")
                    }
                },
                receiveValue: { loginResponse in
                    print("登录成功: \(loginResponse.user.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - async/await 方式示例
    @available(iOS 13.0, *)
    func loginWithAsyncAwaitExample() async {
        do {
            let loginResponse = try await apiService.login(email: "test@example.com", password: "password")
            print("登录成功: \(loginResponse.user.name)")
        } catch {
            print("登录失败: \(error.localizedDescription)")
        }
    }
} 