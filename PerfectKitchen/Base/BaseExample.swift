import UIKit

// MARK: - 使用示例

/// 首页控制器 - 继承自BaseViewController
class HomeViewController: BaseViewController {
    
    override func setupUI() {
        super.setupUI()
        
        title = "首页"
        
        // 添加一个测试按钮
        let button = UIButton(type: .system)
        button.setTitle("显示菜谱列表", for: .normal)
        button.addTarget(self, action: #selector(showRecipeList), for: .touchUpInside)
        
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Demo: 插入一条示例数据（如果表为空）
        DispatchQueue.global().async {
            let dao = RecipeDAO()
            do {
                let existing = try dao.fetchAll()
                if existing.isEmpty {
                    _ = try dao.insert(name: "红烧肉", cuisine: "川菜")
                }
            } catch {
                print("[DB Demo] error: \(error)")
            }
        }
    }
    
    @objc private func showRecipeList() {
        let recipeListVC = RecipeListViewController()
        push(to: recipeListVC)
    }
}

/// 菜谱列表控制器 - 继承自BaseTableViewController
class RecipeListViewController: BaseTableViewController {
    
    // 示例数据
    var recipes = ["红烧肉", "宫保鸡丁", "麻婆豆腐", "糖醋排骨", "清蒸鲈鱼"]
    
    override func setupUI() {
        super.setupUI()
        
        title = "菜谱列表"
        
        // 设置空数据视图
        setEmptyViewContent(
            image: UIImage(systemName: "book.closed"),
            title: "暂无菜谱",
            message: "快去添加一些美味的菜谱吧！"
        )
        
        // 添加下拉刷新
        addRefreshControl()
        
        // 从数据库加载
        DispatchQueue.global().async {
            let dao = RecipeDAO()
            do {
                let rows = try dao.fetchAll()
                let names = rows.map { $0.name }
                DispatchQueue.main.async {
                    if !names.isEmpty {
                        self.recipes = names
                        self.reloadData()
                    }
                }
            } catch {
                print("[DB Demo] fetch error: \(error)")
            }
        }
    }
    
    override func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipeCell")
    }
    
    override func shouldShowEmptyView() -> Bool {
        return recipes.isEmpty
    }
    
    // MARK: - TableView DataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
        cell.textLabel?.text = recipes[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        let recipeName = recipes[indexPath.row]
        let recipeDetailVC = RecipeDetailViewController()
        recipeDetailVC.recipeName = recipeName
        push(to: recipeDetailVC)
    }
    
    // MARK: - Refresh
    
    func handleRefresh() {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recipes.append("新菜谱 \(Date().timeIntervalSince1970)")
            self.reloadData()
            self.endRefreshing()
        }
    }
}

/// 菜谱详情控制器 - 继承自BaseViewController
class RecipeDetailViewController: BaseViewController {
    
    var recipeName: String = ""
    
    override func setupUI() {
        super.setupUI()
        
        title = recipeName
        
        // 设置右侧按钮
        if let navController = navigationController as? BaseNavigationController {
            navController.setupRightButton(
                for: self,
                title: "收藏",
                imageName: nil,
                action: #selector(favoriteAction)
            )
        }
        
        // 添加内容
        let label = UILabel()
        label.text = "这是 \(recipeName) 的详细制作方法..."
        label.numberOfLines = 0
        label.textAlignment = .center
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    @objc private func favoriteAction() {
        showAlert(title: "收藏成功", message: "已将 \(recipeName) 添加到收藏夹") {
            // 收藏成功后的处理
        }
    }
}

/// 网页控制器 - 继承自BaseWebViewController
class WebViewController: BaseWebViewController {
    
    override func setupData() {
        super.setupData()
        
        // 加载一个菜谱网站
        loadURL("https://www.xiachufang.com")
    }
}

// MARK: - 如何在SceneDelegate中使用

/*
 在 SceneDelegate.swift 中使用这些基类：
 
 func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
     guard let windowScene = (scene as? UIWindowScene) else { return }
     
     window = UIWindow(windowScene: windowScene)
     
     // 使用自定义的BaseTabBarController
     let tabBarController = BaseTabBarController()
     
     // 或者手动创建
     let homeVC = HomeViewController()
     let recipeListVC = RecipeListViewController()
     let menuVC = UIViewController() // 你的菜单控制器
     let settingVC = UIViewController() // 你的设置控制器
     
     let homeNav = BaseNavigationController(rootViewController: homeVC)
     let recipeNav = BaseNavigationController(rootViewController: recipeListVC)
     let menuNav = BaseNavigationController(rootViewController: menuVC)
     let settingNav = BaseNavigationController(rootViewController: settingVC)
     
     homeNav.tabBarItem = UITabBarItem(title: "首页", image: UIImage(systemName: "house"), tag: 0)
     recipeNav.tabBarItem = UITabBarItem(title: "菜谱", image: UIImage(systemName: "book"), tag: 1)
     menuNav.tabBarItem = UITabBarItem(title: "我的菜单", image: UIImage(systemName: "heart"), tag: 2)
     settingNav.tabBarItem = UITabBarItem(title: "设置", image: UIImage(systemName: "gearshape"), tag: 3)
     
     tabBarController.viewControllers = [homeNav, recipeNav, menuNav, settingNav]
     
     window?.rootViewController = tabBarController
     window?.makeKeyAndVisible()
 }
 */

// MARK: - 使用技巧

/*
 1. 继承BaseViewController时，重写这些方法：
    - setupUI(): 设置界面元素
    - setupConstraints(): 设置约束
    - setupData(): 设置数据
 
 2. 使用便捷方法：
    - showAlert(), showConfirm(), showActionSheet()
    - showLoading(), hideLoading()
         - push(), presentModal(), goBack()
 
 3. 键盘管理：
    - addKeyboardNotifications() 添加键盘通知
    - setupTapToHideKeyboard() 点击空白处隐藏键盘
 
 4. TableView使用：
    - 重写 shouldShowEmptyView() 控制空数据显示
    - 重写 handleRefresh() 实现下拉刷新
    - 使用 setEmptyViewContent() 自定义空数据视图
 
 5. WebView使用：
    - 设置 urlString 属性自动加载
    - 使用 loadURL(), loadHTML() 加载内容
    - 使用 evaluateJavaScript() 执行JS代码
 */ 
