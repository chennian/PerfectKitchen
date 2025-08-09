# Moya + Codable 网络请求封装

这是一个基于 Moya 和 Codable 的完整网络请求封装，提供了类型安全的网络请求解决方案。

## 📁 文件结构

```
API/
├── NetworkAPI.swift          # API 端点定义（TargetType 实现）
├── NetworkModels.swift       # 数据模型定义（Codable 模型）
├── NetworkError.swift        # 错误处理和错误类型定义
├── NetworkManager.swift      # 网络管理器（核心网络层）
├── APIService.swift          # 业务 API 服务类
└── README.md                # 使用说明文档
```

## ✨ 主要特性

- ✅ **类型安全**: 使用 Codable 协议确保类型安全
- ✅ **多种调用方式**: 支持传统回调、Combine、async/await
- ✅ **完善的错误处理**: 统一的错误类型和处理机制
- ✅ **自动 Token 管理**: 自动处理认证 Token
- ✅ **文件上传支持**: 支持图片和文件上传
- ✅ **网络日志**: 详细的网络请求日志
- ✅ **网络状态指示**: 自动显示/隐藏网络活动指示器

## 🚀 快速开始

### 1. 基础使用

```swift
// 导入必要的模块
import Foundation

// 创建 API 服务实例
let apiService = APIService.shared

// 使用传统回调方式
apiService.login(email: "user@example.com", password: "password") { result in
    switch result {
    case .success(let loginResponse):
        print("登录成功: \(loginResponse.user.name)")
        print("Token: \(loginResponse.token)")
    case .failure(let error):
        print("登录失败: \(error.localizedDescription)")
    }
}
```

### 2. 使用 Combine（iOS 13.0+）

```swift
import Combine

class ViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService = APIService.shared
    
    func login(email: String, password: String) {
        isLoading = true
        
        apiService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] loginResponse in
                    self?.user = loginResponse.user
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
}
```

### 3. 使用 async/await（iOS 13.0+）

```swift
class AuthService {
    private let apiService = APIService.shared
    
    func performLogin(email: String, password: String) async {
        do {
            let loginResponse = try await apiService.login(email: email, password: password)
            print("登录成功: \(loginResponse.user.name)")
            
            // 获取用户详细信息
            let userInfo = try await apiService.getUserInfo(userId: loginResponse.user.id)
            print("用户详情: \(userInfo)")
            
        } catch {
            print("操作失败: \(error.localizedDescription)")
        }
    }
}
```

## 📋 API 使用示例

### 用户认证

```swift
// 登录
apiService.login(email: "user@example.com", password: "password") { result in
    // 处理结果
}

// 注册
apiService.register(email: "new@example.com", password: "password", name: "新用户") { result in
    // 处理结果
}

// 登出
apiService.logout { result in
    // 处理结果
}
```

### 数据操作

```swift
// 获取数据列表（分页）
apiService.fetchDataList(page: 1, limit: 20) { result in
    switch result {
    case .success(let paginatedResponse):
        print("数据总数: \(paginatedResponse.total)")
        print("当前页数据: \(paginatedResponse.items)")
    case .failure(let error):
        print("获取失败: \(error.localizedDescription)")
    }
}

// 获取数据详情
apiService.fetchDataDetail(id: "123") { result in
    // 处理结果
}

// 删除数据
apiService.deleteData(id: "123") { result in
    // 处理结果
}
```

### 文件上传

```swift
// 上传图片
let image = UIImage(named: "example")!
apiService.uploadImage(image, compression: 0.8) { result in
    switch result {
    case .success(let uploadResponse):
        print("上传成功: \(uploadResponse.url)")
    case .failure(let error):
        print("上传失败: \(error.localizedDescription)")
    }
}

// 上传文件
let fileURL = Bundle.main.url(forResource: "document", withExtension: "pdf")!
apiService.uploadFile(fileURL: fileURL) { result in
    // 处理结果
}
```

## 🔧 自定义配置

### 1. 修改基础URL

在 `NetworkAPI.swift` 中修改 `baseURL`:

```swift
var baseURL: URL {
    return URL(string: "https://your-api-domain.com")!
}
```

### 2. 添加新的 API 端点

在 `NetworkAPI.swift` 中添加新的 case:

```swift
enum NetworkAPI {
    // 现有的 API...
    case getNews(page: Int)
    case createNews(title: String, content: String)
}

// 在 TargetType 扩展中添加对应的实现
extension NetworkAPI: TargetType {
    var path: String {
        switch self {
        // 现有的 path...
        case .getNews:
            return "/news"
        case .createNews:
            return "/news"
        }
    }
    
    var method: Moya.Method {
        switch self {
        // 现有的 method...
        case .getNews:
            return .get
        case .createNews:
            return .post
        }
    }
    
    var task: Task {
        switch self {
        // 现有的 task...
        case .getNews(let page):
            return .requestParameters(parameters: ["page": page], encoding: URLEncoding.queryString)
        case .createNews(let title, let content):
            let parameters = ["title": title, "content": content]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
}
```

### 3. 创建新的数据模型

在 `NetworkModels.swift` 中添加新模型:

```swift
struct News: Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
    }
}
```

### 4. 在 APIService 中添加新方法

```swift
extension APIService {
    func getNews(page: Int, completion: @escaping NetworkCompletion<PaginatedResponse<News>>) {
        let target = NetworkAPI.getNews(page: page)
        networkManager.request(target, type: PaginatedResponse<News>.self, completion: completion)
    }
    
    func createNews(title: String, content: String, completion: @escaping NetworkCompletion<News>) {
        let target = NetworkAPI.createNews(title: title, content: content)
        networkManager.request(target, type: News.self, completion: completion)
    }
}
```

## 🛠 错误处理

### 错误类型

```swift
enum NetworkError: Error {
    case invalidURL          // 无效URL
    case noData             // 无数据
    case decodingError      // 解析错误
    case encodingError      // 编码错误
    case moyaError          // Moya错误
    case serverError        // 服务器错误
    case networkUnavailable // 网络不可用
    case timeout            // 超时
    case unauthorized       // 未授权
    case forbidden          // 禁止访问
    case notFound           // 资源不存在
    case unknown            // 未知错误
}
```

### 错误处理示例

```swift
apiService.login(email: email, password: password) { result in
    switch result {
    case .success(let loginResponse):
        // 处理成功
        break
    case .failure(let error):
        switch error {
        case .unauthorized:
            // 处理认证失败
            print("请重新登录")
        case .networkUnavailable:
            // 处理网络不可用
            print("请检查网络连接")
        case .serverError(let code, let message):
            // 处理服务器错误
            print("服务器错误(\(code)): \(message ?? "")")
        default:
            // 处理其他错误
            print("错误: \(error.localizedDescription)")
        }
    }
}
```

## 📝 注意事项

1. **Token 管理**: Token 会自动保存在 UserDefaults 中，应用重启后会自动加载
2. **网络日志**: 在 Debug 模式下会自动打印详细的网络请求日志
3. **错误处理**: 网络错误会自动显示，也可以手动处理
4. **线程安全**: 所有网络请求都在后台线程执行，回调会自动切换到主线程
5. **内存管理**: 使用 weak self 避免循环引用

## 🔄 升级指南

如果需要从其他网络库迁移到这个封装，主要步骤：

1. 将现有的网络请求定义迁移到 `NetworkAPI` 枚举
2. 将数据模型改为实现 `Codable` 协议
3. 使用 `APIService` 替换原有的网络请求调用
4. 更新错误处理逻辑

## 📄 许可证

此代码遵循项目的许可证协议。 