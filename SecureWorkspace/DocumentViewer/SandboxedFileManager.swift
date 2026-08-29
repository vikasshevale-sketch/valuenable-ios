import Foundation

public final class SandboxedFileManager {
    public static let shared = SandboxedFileManager()
    
    private let secureDirectory: URL
    
    private init() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("SecureSandboxDocuments", isDirectory: true)
        self.secureDirectory = tempDir
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: [
            .protectionKey: FileProtectionType.completeUnlessOpen
        ])
    }
    
    public func saveSecureAttachment(data: Data, originalFileName: String) -> URL? {
        let sanitizedName = originalFileName.replacingOccurrences(of: "/", with: "_")
        let destinationURL = secureDirectory.appendingPathComponent(UUID().uuidString + "_" + sanitizedName)
        
        do {
            try data.write(to: destinationURL, options: [.atomic, .completeFileProtection])
            return destinationURL
        } catch {
            return nil
        }
    }
    
    public func purgeAllTemporaryFiles() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: secureDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            #if DEBUG
            print("[SandboxedFileManager] Cleanup error: \(error)")
            #endif
        }
    }
}
