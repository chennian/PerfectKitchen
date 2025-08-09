import UIKit

class BaseNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarAppearance()
        setupGestures()
    }
    
    // MARK: - Private Methods
    
    /// 设置导航栏外观
    private func setupNavigationBarAppearance() {
        // 设置导航栏背景色
        navigationBar.backgroundColor = UIColor.white
        
        // 设置导航栏阴影
        navigationBar.layer.shadowColor = UIColor.black.cgColor
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 1)
        navigationBar.layer.shadowOpacity = 0.1
        navigationBar.layer.shadowRadius = 4
        
        // 设置标题颜色
        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        // 设置返回按钮颜色
        navigationBar.tintColor = UIColor.systemBlue
        
        // 如果需要支持iOS 13+的外观设置
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // 设置标题样式
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ]
            
            // 设置大标题样式
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.black,
                .font: UIFont.systemFont(ofSize: 34, weight: .bold)
            ]
            
            // 移除底部线条
            appearance.shadowImage = UIImage()
            appearance.shadowColor = UIColor.clear
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
    }
    
    /// 设置手势
    private func setupGestures() {
        // 启用侧滑返回
        interactivePopGestureRecognizer?.delegate = self
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 如果不是根控制器，隐藏TabBar
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
        }
        
        super.pushViewController(viewController, animated: animated)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension BaseNavigationController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只有在有多个控制器时才允许侧滑返回
        return viewControllers.count > 1
    }
}

// MARK: - Custom Navigation Methods

extension BaseNavigationController {
    
    /// 自定义返回按钮
    func setupCustomBackButton(for viewController: UIViewController, title: String? = nil) {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackButtonTap)
        )
        
        if let title = title {
            let titleButton = UIBarButtonItem(
                title: title,
                style: .plain,
                target: self,
                action: #selector(handleBackButtonTap)
            )
            viewController.navigationItem.leftBarButtonItems = [backButton, titleButton]
        } else {
            viewController.navigationItem.leftBarButtonItem = backButton
        }
    }
    
    @objc private func handleBackButtonTap() {
        popViewController(animated: true)
    }
    
    /// 设置右侧按钮
    func setupRightButton(for viewController: UIViewController, title: String?, imageName: String?, action: Selector) {
        var rightButton: UIBarButtonItem
        
        if let title = title {
            rightButton = UIBarButtonItem(
                title: title,
                style: .plain,
                target: viewController,
                action: action
            )
        } else if let imageName = imageName {
            rightButton = UIBarButtonItem(
                image: UIImage(systemName: imageName),
                style: .plain,
                target: viewController,
                action: action
            )
        } else {
            return
        }
        
        viewController.navigationItem.rightBarButtonItem = rightButton
    }
    
    /// 设置导航栏标题
    func setupNavigationTitle(_ title: String, for viewController: UIViewController) {
        viewController.navigationItem.title = title
    }
} 