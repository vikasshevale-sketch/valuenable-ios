import UIKit
import Combine

public final class ScreenCaptureMonitor: ObservableObject {
    public static let shared = ScreenCaptureMonitor()
    
    @Published public private(set) var isScreenCaptured: Bool = false
    
    private init() {
        self.isScreenCaptured = UIScreen.main.isCaptured
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenCaptured = UIScreen.main.isCaptured
        }
    }
}
