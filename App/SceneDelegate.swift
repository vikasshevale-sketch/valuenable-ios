import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let mainVC = SecureWebViewController()
        let navController = UINavigationController(rootViewController: mainVC)
        
        window.rootViewController = navController
        self.window = window
        window.makeKeyAndVisible()
        
        // Start monitoring for screen capture / video sharing
        ScreenCaptureMonitor.shared.startMonitoring(in: window)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Delete all cached files on exit
        SandboxedFileManager.shared.purgeTemporaryFiles()
    }
}
