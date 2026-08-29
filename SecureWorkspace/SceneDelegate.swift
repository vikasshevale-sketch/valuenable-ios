import UIKit
public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?
    private var privacyMaskView: UIView?
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        if JailbreakDetector.isDeviceCompromised() {
            let alertController = UIViewController()
            window.rootViewController = alertController
            self.window = window
            window.makeKeyAndVisible()
            
            let alert = UIAlertController(
                title: "Security Violation",
                message: "This device is compromised (jailbroken or modified). Valuenable Workspace access is blocked.",
                preferredStyle: .alert
            )
            alertController.present(alert, animated: true)
            return
        }
        
        let rootVC = SecureWebViewController()
        let navController = UINavigationController(rootViewController: rootVC)
        navController.setNavigationBarHidden(true, animated: false)
        
        window.rootViewController = navController
        self.window = window
        window.makeKeyAndVisible()
        
        #if !targetEnvironment(simulator)
        BiometricAuthManager.shared.authenticateUser { _, _ in }
        #endif
    }
    public func sceneWillResignActive(_ scene: UIScene) {
        showPrivacyMask()
    }
    public func sceneDidBecomeActive(_ scene: UIScene) {
        hidePrivacyMask()
        
        #if !targetEnvironment(simulator)
        if BiometricAuthManager.shared.shouldRequireUnlock() {
            BiometricAuthManager.shared.authenticateUser { [weak self] success, _ in
                if !success {
                    self?.showPrivacyMask()
                }
            }
        }
        #endif
    }
    public func sceneDidEnterBackground(_ scene: UIScene) {
        #if !targetEnvironment(simulator)
        BiometricAuthManager.shared.recordBackgroundEntry()
        #endif
    }
    private func showPrivacyMask() {
        guard privacyMaskView == nil, let window = window else { return }
        
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let logoLabel = UILabel()
        logoLabel.text = "🔒 Valuenable Secure Workspace"
        logoLabel.textColor = .white
        logoLabel.font = .systemFont(ofSize: 20, weight: .bold)
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.contentView.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: blurView.centerYAnchor)
        ])
        
        window.addSubview(blurView)
        self.privacyMaskView = blurView
    }
    private func hidePrivacyMask() {
        privacyMaskView?.removeFromSuperview()
        privacyMaskView = nil
    }
}
