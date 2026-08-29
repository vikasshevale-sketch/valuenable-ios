import Foundation
import LocalAuthentication

public final class BiometricAuthManager {
    public static let shared = BiometricAuthManager()
    
    private var lastBackgroundTimestamp: Date?
    private let autoLockTimeoutSeconds: TimeInterval = 60.0
    
    private init() {}
    
    public func recordBackgroundEntry() {
        self.lastBackgroundTimestamp = Date()
    }
    
    public func shouldRequireUnlock() -> Bool {
        guard let lastTimestamp = lastBackgroundTimestamp else {
            return true
        }
        let elapsed = Date().timeIntervalSince(lastTimestamp)
        return elapsed > autoLockTimeoutSeconds
    }
    
    public func authenticateUser(reason: String = "Unlock Valuenable Secure Workspace", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    if success {
                        self.lastBackgroundTimestamp = nil
                    }
                    completion(success, evalError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
}
