import UIKit
import WebKit
import Combine

/// Secure Google Workspace web container.
///
/// Important: Google authentication is a browser-managed flow. We intentionally
/// do NOT intercept, cancel, or rewrite requests to accounts.google.com.
/// Rewriting Google authentication requests (especially adding custom headers)
/// can break redirects, cookies, and the Google sign-in flow on iOS.
public final class SecureWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {

    private var webView: WKWebView!
    private var cancellables = Set<AnyCancellable>()
    private let screenShareBlockerView = UIView()
    private let progressView = UIProgressView(progressViewStyle: .default)

    // Workspace-specific Gmail URL. Google will use the normal iOS-compatible
    // sign-in flow and return to this Workspace URL after authentication.
    private let startURL = URL(string: "https://mail.google.com/a/valuenable.in/")!

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupScreenCaptureProtection()
        loadWorkspace()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let configuration = WKWebViewConfiguration()
        // Keep a persistent session so users do not have to authenticate on every launch.
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
        // Do not add X-GoogApps-Allowed-Domains or any other custom header here.
        // Google authentication depends on its normal request/redirect/cookie flow.
        webView.load(URLRequest(url: startURL))
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        }
    }

    // MARK: - WKNavigationDelegate

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let host = url.host?.lowercased() ?? ""

        // Google authentication is allowed to navigate normally. Do not cancel
        // and reload accounts.google.com requests; doing so can break sign-in.
        if !DomainGuard.isHostAllowed(host) {
            #if DEBUG
            print("[DomainGuard] Blocked unauthorized navigation to: \(url.absoluteString)")
            #endif
            showDomainBlockedAlert(host: host)
            decisionHandler(.cancel)
            return
        }

        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }

        decisionHandler(.allow)
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logNavigationError("navigation", error: error)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logNavigationError("provisional navigation", error: error)
    }

    private func logNavigationError(_ stage: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        print("[WebView] \(stage) failed: domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription)")
        #endif
    }

    // MARK: - WKDownloadDelegate

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    public func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let safeName = suggestedFilename.isEmpty ? "download" : suggestedFilename
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "_" + safeName)
        completionHandler(temporaryURL)
    }

    public func downloadDidFinish(_ download: WKDownload) {}

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        #if DEBUG
        print("[Download] Failed: \(error.localizedDescription)")
        #endif
    }

    // MARK: - Alerts

    private func showDomainBlockedAlert(host: String) {
        let alert = UIAlertController(
            title: "Access Restricted",
            message: "Navigation outside of the authorized Valuenable Google Workspace is blocked by security policy.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    deinit {
        webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
}
