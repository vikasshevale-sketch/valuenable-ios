import Foundation

class SandboxedFileManager {
    static let shared = SandboxedFileManager()
    
    private var tempDirectory: URL {
        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("SecureTemp", isDirectory: true)
        if !FileManager.default.fileExists(atPath: path.path) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
        return path
    }

    func saveTemporaryFile(data: Data, fileName: String) -> URL? {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .completeFileProtection)
            return fileURL
        } catch {
            return nil
        }
    }

    func purgeTemporaryFiles() {
        try? FileManager.default.removeItem(at: tempDirectory)
    }
}
