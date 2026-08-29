import UIKit

public final class JailbreakDetector {
    
    public static func isDeviceCompromised() -> Bool {
        #if targetEnvironment(simulator)
        return false // Ignore simulator during development
        #else
        return checkKnownJailbreakFiles() ||
               checkJailbreakSchemes() ||
               checkRestrictedDirectoryWrite() ||
               checkDynamicLibraryInjection()
        #endif
    }
    
    private static func checkKnownJailbreakFiles() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app"
        ]
        
        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    private static func checkJailbreakSchemes() -> Bool {
        guard let url = URL(string: "cydia://package/com.example.package") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    private static func checkRestrictedDirectoryWrite() -> Bool {
        let path = "/private/jailbreak_test_\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: path)
            return true // Successfully wrote outside sandbox!
        } catch {
            return false
        }
    }
    
    private static func checkDynamicLibraryInjection() -> Bool {
        let suspiciousLibraries = ["Substrate", "FridaGadget", "cynject", "SSLKillSwitch"]
        for index in 0..<_dyld_image_count() {
            if let imageName = _dyld_get_image_name(index) {
                let name = String(cString: imageName)
                for suspicious in suspiciousLibraries {
                    if name.contains(suspicious) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
