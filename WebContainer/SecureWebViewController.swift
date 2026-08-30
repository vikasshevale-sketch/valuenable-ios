import UIKit
import WebKit

class SecureWebViewController: UIViewController, WKNavigationDelegate, WKDownloadDelegate {
    private var webView: WKWebView!
    private let secureContainer = SecureContainerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSecureWebView()
    }

    private func setupSecureWebView() {
        let config = WKWebViewConfiguration()
        
        // Ephemeral data store ensures session cookies stay isolated from Safari and other apps
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.userContentController.addUserScript(WebSecurityScripts.copyProtectionScript)
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Wrap webView inside screenshot-protected view layer
        view.addSubview(secureContainer)
        secureContainer.frame = view.bounds
        secureContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        secureContainer.embed(childView: webView)

        // Load entry workspace point
        if let url = URL(string: "https://valuenable.in") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        // Validate destination URL using DomainGuard
        if DomainGuard.isDomainAllowed(url: url) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            showAccessRestrictedAlert()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Intercept file downloads
        if let mimeType = navigationResponse.response.mimeType, !mimeType.contains("text/html") && !mimeType.contains("application/json") {
            if #available(iOS 14.5, *) {
                decisionHandler(.download)
                return
            }
        }
        decisionHandler(.allow)
    }

    // MARK: - WKDownloadDelegate
    @available(iOS 15.0, *)
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let tempURL = SandboxedFileManager.shared.saveTemporaryFile(data: Data(), fileName: suggestedFilename)
        completionHandler(tempURL)
    }

    @available(iOS 15.0, *)
    func downloadDidFinish(_ download: WKDownload) {
        // Handle completed internal preview loading logic
    }

    private func showAccessRestrictedAlert() {
        let alert = UIAlertController(
            title: "Access Restricted",
            message: "Navigation outside of the authorized 'valuenable.in' workspace is blocked for security.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SecureWebViewController: WKUIDelegate {
    // Disable web view context menu callouts
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        completionHandler(nil)
    }
}
