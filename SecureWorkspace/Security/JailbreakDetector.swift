import UIKit
import WebKit
import Combine
public final class SecureWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    
    private var webView: WKWebView!
    private var cancellables = Set<AnyCancellable>()
    private let screenShareBlockerView = UIView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    private let startURL = URL(string: "https://mail.google.com/a/valuenable.in")!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScreenCaptureProtection()
        loadWorkspace()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.userContentController.addUserScript(WebSecurityScripts.dlpPreventionScript)
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        let secureContainer = SecureContainerView(contentView: webView)
        view.addSubview(secureContainer)
        secureContainer.pinToSuperview()
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        setupScreenShareBlockerOverlay()
    }
    
    private func setupScreenShareBlockerOverlay() {
        screenShareBlockerView.backgroundColor = .black
        screenShareBlockerView.translatesAutoresizingMaskIntoConstraints = false
        
        let warningLabel = UILabel()
        warningLabel.text = "🔒 Screen sharing or recording is blocked by Valuenable Security Policy."
        warningLabel.textColor = .white
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        
        screenShareBlockerView.addSubview(warningLabel)
        NSLayoutConstraint.activate([
            warningLabel.centerYAnchor.constraint(equalTo: screenShareBlockerView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: screenShareBlockerView.leadingAnchor, constant: 32),
            warningLabel.trailingAnchor.constraint(equalTo: screenShareBlockerView.trailingAnchor, constant: -32)
        ])
        
        view.addSubview(screenShareBlockerView)
        screenShareBlockerView.pinToSuperview()
        screenShareBlockerView.isHidden = true
    }
    
    private func setupScreenCaptureProtection() {
        ScreenCaptureMonitor.shared.$isScreenCaptured
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCaptured in
                self?.screenShareBlockerView.isHidden = !isCaptured
            }
            .store(in: &cancellables)
    }
    
    private func loadWorkspace() {
        var request = URLRequest(url: startURL)
        DomainGuard.applyDomainRestrictionHeaders(to: &request)
        webView.load(request)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        }
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let host = url.host?.lowercased() ?? ""
        
        if !DomainGuard.isHostAllowed(host) {
            showDomainBlockedAlert(host: host)
            decisionHandler(.cancel)
            return
        }
        
        if host.contains("accounts.google.com") || host.contains("google.com") {
            if navigationAction.request.value(forHTTPHeaderField: DomainGuard.googleAllowedDomainsHeader) == nil {
                decisionHandler(.cancel)
                var customRequest = navigationAction.request
                DomainGuard.applyDomainRestrictionHeaders(to: &customRequest)
                webView.load(customRequest)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    // MARK: - WKDownloadDelegate
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_" + suggestedFilename)
        completionHandler(temporaryURL)
    }
    
    public func downloadDidFinish(_ download: WKDownload) {
        // Download complete inside sandbox
    }
    
    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        #if DEBUG
        print("[Download] Failed: \(error.localizedDescription)")
        #endif
    }
    
    private func showDomainBlockedAlert(host: String) {
        let alert = UIAlertController(
            title: "Access Restricted",
            message: "Navigation outside of the authorized 'valuenable.in' workspace is blocked for security.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
}
