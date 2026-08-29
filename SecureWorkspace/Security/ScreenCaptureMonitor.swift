import UIKit
import Combine
public final class ScreenCaptureMonitor: ObservableObject {
    public static let shared = ScreenCaptureMonitor()
    
    @Published public private(set) var isScreenCaptured: Bool = false
    
    private init() {
        checkCurrentCaptureState()
        setupCaptureObserver()
    }
    
    private func checkCurrentCaptureState() {
        #if targetEnvironment(simulator)
        self.isScreenCaptured = false // Allow browser video streaming in Appetize
        #else
        self.isScreenCaptured = UIScreen.main.isCaptured
        #endif
    }
    
    private func setupCaptureObserver() {
        #if !targetEnvironment(simulator)
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.isScreenCaptured = UIScreen.main.isCaptured
        }
        #endif
    }
}
