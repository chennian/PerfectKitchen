import UIKit

class BaseTableViewController: BaseViewController {
    
    // MARK: - Properties
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: tableViewStyle)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = UIColor.systemBackground
        tableView.tableFooterView = UIView()
        
        // 设置估算高度以提高性能
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        
        // 去除多余的分割线
        tableView.tableFooterView = UIView()
        
        return tableView
    }()
    
    /// TableView样式
    var tableViewStyle: UITableView.Style = .plain
    
    /// 是否显示空数据视图
    var showEmptyView: Bool = true
    
    /// 空数据视图
    lazy var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "tray")
        imageView.tintColor = UIColor.systemGray3
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "暂无数据"
        label.textColor = UIColor.systemGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        super.setupUI()
        
        view.addSubview(tableView)
        registerCells()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Methods
    
    /// 注册Cell - 子类重写
    func registerCells() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
    }
    
    /// 刷新数据
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyView()
        }
    }
    
    /// 更新空数据视图
    private func updateEmptyView() {
        if showEmptyView && shouldShowEmptyView() {
            tableView.backgroundView = emptyView
        } else {
            tableView.backgroundView = nil
        }
    }
    
    /// 是否应该显示空数据视图 - 子类重写
    func shouldShowEmptyView() -> Bool {
        return false
    }
    
    /// 设置自定义空数据视图
    func setCustomEmptyView(_ view: UIView) {
        emptyView = view
    }
    
    /// 设置空数据视图内容
    func setEmptyViewContent(image: UIImage?, title: String?, message: String? = nil) {
        emptyView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        
        if let image = image {
            let imageView = UIImageView(image: image)
            imageView.tintColor = UIColor.systemGray3
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
            stackView.addArrangedSubview(imageView)
        }
        
        if let title = title {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.textColor = UIColor.systemGray
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            titleLabel.textAlignment = .center
            stackView.addArrangedSubview(titleLabel)
        }
        
        if let message = message {
            let messageLabel = UILabel()
            messageLabel.text = message
            messageLabel.textColor = UIColor.systemGray2
            messageLabel.font = UIFont.systemFont(ofSize: 14)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stackView.addArrangedSubview(messageLabel)
        }
        
        emptyView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: emptyView.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: emptyView.trailingAnchor, constant: -40)
        ])
    }
}

// MARK: - UITableViewDataSource

extension BaseTableViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 // 子类重写
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell() // 子类重写
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // 子类重写
    }
}

// MARK: - UITableViewDelegate

extension BaseTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 子类重写
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

// MARK: - Refresh Control

extension BaseTableViewController {
    
    /// 添加下拉刷新
    func addRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        // 子类重写实现刷新逻辑
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    /// 结束刷新
    func endRefreshing() {
        DispatchQueue.main.async {
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: - Scroll Methods

extension BaseTableViewController {
    
    /// 滚动到顶部
    func scrollToTop(animated: Bool = true) {
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }
    
    /// 滚动到底部
    func scrollToBottom(animated: Bool = true) {
        let lastSection = tableView.numberOfSections - 1
        if lastSection >= 0 {
            let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
            if lastRow >= 0 {
                let indexPath = IndexPath(row: lastRow, section: lastSection)
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
} 