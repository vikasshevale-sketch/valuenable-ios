import UIKit
import Combine

/// Monitors screen recording, AirPlay mirroring, and video call screen sharing (Zoom, Teams, Google Meet).
/// When active, notifies the UI to display a full-screen blackout warning overlay.
public final class ScreenCaptureMonitor: ObservableObject {
    public static let shared = ScreenCaptureMonitor()
    
    @Published public private(set) var isScreenCaptured: Bool = false
    
    private init() {
        checkCurrentCaptureState()
        setupCaptureObserver()
    }
    
    private func checkCurrentCaptureState() {
        self.isScreenCaptured = UIScreen.main.isCaptured
    }
    
    private func setupCaptureObserver() {
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isScreenCaptured = UIScreen.main.isCaptured
            #if DEBUG
            print("[SecurityGuard] Screen capture state changed: \(self.isScreenCaptured)")
            #endif
        }
    }
}
