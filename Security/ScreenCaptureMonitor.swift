import UIKit

class ScreenCaptureMonitor {
    static let shared = ScreenCaptureMonitor()
    private var overlayView: UIView?

    func startMonitoring(in window: UIWindow?) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureStateChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        checkCurrentCaptureStatus(window: window)
    }

    @objc private func screenCaptureStateChanged() {
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                self.checkCurrentCaptureStatus(window: window)
            }
        }
    }

    private func checkCurrentCaptureStatus(window: UIWindow?) {
        let isCaptured = UIScreen.main.isCaptured
        if isCaptured {
            showSecurityOverlay(on: window)
        } else {
            removeSecurityOverlay()
        }
    }

    private func showSecurityOverlay(on window: UIWindow?) {
        guard overlayView == nil, let window = window else { return }
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Screen sharing or recording is disabled for this secure workspace."
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -20),
            label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        
        window.addSubview(overlay)
        self.overlayView = overlay
    }

    private func removeSecurityOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
}
