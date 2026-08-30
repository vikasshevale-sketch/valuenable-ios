import UIKit
import WebKit

class SecureWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let secureContainer = SecureContainerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSecureWebView()
    }

    private func setupSecureWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.userContentController.addUserScript(WebSecurityScripts.copyProtectionScript)
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        view.addSubview(secureContainer)
        secureContainer.frame = view.bounds
        secureContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        secureContainer.embed(childView: webView)

        if let url = URL(string: "https://valuenable.in") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if DomainGuard.isDomainAllowed(url: url) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            showAccessRestrictedAlert()
        }
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

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        completionHandler(nil)
    }
}

// Separate extension for iOS 14.5+ download handling to prevent compilation failures on older deployment targets
@available(iOS 14.5, *)
extension SecureWebViewController: WKDownloadDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let mimeType = navigationResponse.response.mimeType, !mimeType.contains("text/html") && !mimeType.contains("application/json") {
            decisionHandler(.download)
            return
        }
        decisionHandler(.allow)
    }

    @available(iOS 15.0, *)
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let tempURL = SandboxedFileManager.shared.saveTemporaryFile(data: Data(), fileName: suggestedFilename)
        completionHandler(tempURL)
    }
}