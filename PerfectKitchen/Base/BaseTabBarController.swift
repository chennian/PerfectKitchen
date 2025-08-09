import UIKit

class BaseTabBarController: UITabBarController {
    
    static let shared = BaseTabBarController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBarAppearance()
        setupTabBarItems()
    }
    
    // MARK: - Private Methods
    
    /// 设置TabBar外观
    private func setupTabBarAppearance() {
        // 设置TabBar背景色
        tabBar.backgroundColor = UIColor.white
        
        // 设置TabBar阴影
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -1)
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowRadius = 4
        
        // 设置选中和未选中的颜色
        tabBar.tintColor = UIColor.systemBlue
        tabBar.unselectedItemTintColor = UIColor.systemGray
        
        // 如果需要支持iOS 13+的外观设置
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // 设置选中状态
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            
            // 设置未选中状态
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.systemGray
            ]
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    /// 设置TabBar子控制器
    private func setupTabBarItems() {
        // 首页
        let homeVC = createNavigationController(
            rootViewController: HomeViewController(), // 替换为你的首页控制器
            title: "首页",
            imageName: "house",
            selectedImageName: "house.fill"
        )
        
        // 菜谱
        let recipeVC = createNavigationController(
            rootViewController: RecipeListViewController(), // 替换为你的菜谱控制器
            title: "菜谱",
            imageName: "book",
            selectedImageName: "book.fill"
        )
        
        // 我的菜单
        let menuVC = createNavigationController(
            rootViewController: UIViewController(), // 替换为你的菜单控制器
            title: "我的菜单",
            imageName: "heart",
            selectedImageName: "heart.fill"
        )
        
        // 设置
        let settingVC = createNavigationController(
            rootViewController: UIViewController(), // 替换为你的设置控制器
            title: "设置",
            imageName: "gearshape",
            selectedImageName: "gearshape.fill"
        )
        
        viewControllers = [homeVC, recipeVC, menuVC, settingVC]
    }
    
    /// 创建导航控制器
    private func createNavigationController(
        rootViewController: UIViewController,
        title: String,
        imageName: String,
        selectedImageName: String
    ) -> BaseNavigationController {
        
        let navigationController = BaseNavigationController(rootViewController: rootViewController)
        
        // 设置TabBarItem
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: UIImage(systemName: selectedImageName)
        )
        
        return navigationController
    }
}

// MARK: - TabBar Badge Management

extension BaseTabBarController {
    
    /// 设置TabBar徽章
    func setBadge(count: Int, at index: Int) {
        guard index < tabBar.items?.count ?? 0 else { return }
        
        let badgeValue = count > 0 ? (count > 99 ? "99+" : "\(count)") : nil
        tabBar.items?[index].badgeValue = badgeValue
    }
    
    /// 清除TabBar徽章
    func clearBadge(at index: Int) {
        guard index < tabBar.items?.count ?? 0 else { return }
        tabBar.items?[index].badgeValue = nil
    }
} 
