import UIKit

class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 是否显示导航栏
    var showNavigationBar: Bool = true {
        didSet {
            navigationController?.setNavigationBarHidden(!showNavigationBar, animated: true)
        }
    }
    
    /// 是否允许侧滑返回
    var enableInteractivePopGesture: Bool = true {
        didSet {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = enableInteractivePopGesture
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 设置导航栏显示状态
        navigationController?.setNavigationBarHidden(!showNavigationBar, animated: animated)
        
        // 设置状态栏样式
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 设置侧滑返回手势
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enableInteractivePopGesture
    }
    
    // MARK: - Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    // MARK: - Setup Methods (子类重写)
    
    /// 设置UI - 子类重写
    func setupUI() {
        view.backgroundColor = UIColor.systemBackground
    }
    
    /// 设置约束 - 子类重写
    func setupConstraints() {
        
    }
    
    /// 设置数据 - 子类重写
    func setupData() {
        
    }
    
    // MARK: - Memory Management
    
    deinit {
        removeKeyboardNotifications()
        NotificationCenter.default.removeObserver(self)
        print("✅ \(String(describing: type(of: self))) 已释放")
    }
}

// MARK: - Loading & Alert

extension BaseViewController {
    
    /// 显示加载指示器
    func showLoading() {
        let alert = UIAlertController(title: nil, message: "加载中...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        
        alert.setValue(loadingIndicator, forKey: "accessoryView")
        present(alert, animated: true)
    }
    
    /// 隐藏加载指示器
    func hideLoading() {
        dismiss(animated: true)
    }
    
    /// 显示提示框
    func showAlert(title: String?, message: String?, confirmTitle: String = "确定", confirmHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirmHandler?()
        }
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    /// 显示确认对话框
    func showConfirm(title: String?, message: String?, confirmTitle: String = "确定", cancelTitle: String = "取消", confirmHandler: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirmHandler?()
        }
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    /// 显示操作表
    func showActionSheet(title: String?, message: String?, actions: [(title: String, style: UIAlertAction.Style, handler: (() -> Void)?)] = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
            }
            alert.addAction(alertAction)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        // 适配iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
}

// MARK: - Navigation

extension BaseViewController {
    
    /// 返回上一页
    func goBack() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    /// 返回根控制器
    func goBackToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// 跳转到指定控制器
    func push(to viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }
    
    /// 模态展示控制器
    func presentModal(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        present(viewController, animated: animated, completion: completion)
    }
}

// MARK: - Keyboard

extension BaseViewController {
    
    /// 添加键盘通知
    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    /// 移除键盘通知
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        // 子类重写处理键盘显示
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        // 子类重写处理键盘隐藏
    }
    
    /// 点击空白处收起键盘
    func setupTapToHideKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
}

 