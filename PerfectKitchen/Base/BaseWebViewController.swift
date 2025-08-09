import UIKit
import WebKit

class BaseWebViewController: BaseViewController {
    
    // MARK: - Properties
    
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        webView.backgroundColor = UIColor.systemBackground
        
        // 允许返回手势
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }()
    
    /// 进度条
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.tintColor = UIColor.systemBlue
        progressView.isHidden = true
        return progressView
    }()
    
    /// 要加载的URL
    var urlString: String?
    
    /// 是否显示进度条
    var showProgress: Bool = true
    
    /// 是否显示导航按钮
    var showNavigationButtons: Bool = true
    
    // MARK: - Lifecycle
    
    override func setupUI() {
        super.setupUI()
        
        view.addSubview(webView)
        view.addSubview(progressView)
        
        setupNavigationItems()
        setupKVO()
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func setupData() {
        super.setupData()
        
        if let urlString = urlString {
            loadURL(urlString)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 停止加载
        webView.stopLoading()
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "canGoForward")
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationItems() {
        if showNavigationButtons {
            let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                style: .plain,
                target: self,
                action: #selector(goBackAction)
            )
            
            let forwardButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.right"),
                style: .plain,
                target: self,
                action: #selector(goForwardAction)
            )
            
            let refreshButton = UIBarButtonItem(
                barButtonSystemItem: .refresh,
                target: self,
                action: #selector(refreshAction)
            )
            
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            
            toolbarItems = [backButton, space, forwardButton, space, refreshButton]
            navigationController?.setToolbarHidden(false, animated: false)
            
            backButton.isEnabled = false
            forwardButton.isEnabled = false
        }
    }
    
    private func setupKVO() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
    }
    
    private func updateNavigationButtons() {
        if let backButton = toolbarItems?.first {
            backButton.isEnabled = webView.canGoBack
        }
        
        if let forwardButton = toolbarItems?[2] {
            forwardButton.isEnabled = webView.canGoForward
        }
    }
    
    // MARK: - Actions
    
    @objc private func goBackAction() {
        webView.goBack()
    }
    
    @objc private func goForwardAction() {
        webView.goForward()
    }
    
    @objc private func refreshAction() {
        webView.reload()
    }
    
    // MARK: - Public Methods
    
    /// 加载URL
    func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            showAlert(title: "错误", message: "无效的URL")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    /// 加载HTML字符串
    func loadHTML(_ htmlString: String, baseURL: URL? = nil) {
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }
    
    /// 执行JavaScript
    func evaluateJavaScript(_ script: String, completion: ((Result<Any, Error>) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(result as Any))
            }
        }
    }
    
    /// 清除缓存
    func clearCache() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date) {
            print("缓存清除完成")
        }
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case "estimatedProgress":
            if showProgress {
                let progress = Float(webView.estimatedProgress)
                progressView.setProgress(progress, animated: true)
                
                if progress == 1.0 {
                    UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut) {
                        self.progressView.isHidden = true
                    }
                } else {
                    progressView.isHidden = false
                }
            }
            
        case "title":
            title = webView.title
            
        case "canGoBack", "canGoForward":
            updateNavigationButtons()
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - WKNavigationDelegate

extension BaseWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if showProgress {
            progressView.isHidden = false
            progressView.setProgress(0.0, animated: false)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if showProgress {
            progressView.setProgress(1.0, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.progressView.isHidden = true
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if showProgress {
            progressView.isHidden = true
        }
        
        showAlert(title: "加载失败", message: error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // 处理特殊URL scheme
        if !(url.scheme?.hasPrefix("http") ?? false) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension BaseWebViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        showAlert(title: "提示", message: message) {
            completionHandler()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
        showConfirm(title: "确认", message: message) {
            completionHandler(true)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        // 处理新窗口请求
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        
        return nil
    }
}

// MARK: - UIScrollViewDelegate

extension BaseWebViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 子类可以重写处理滚动事件
    }
} 