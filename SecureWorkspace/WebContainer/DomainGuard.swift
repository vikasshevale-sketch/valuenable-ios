import Foundation

public final class DomainGuard {
    public static let allowedCompanyDomain = "valuenable.in"

    /// Hosts/suffixes required by Google Workspace web applications and the
    /// Google authentication flow. Authentication requests are allowed through
    /// unchanged; this class is only responsible for navigation allow/deny.
    private static let allowedDomainSuffixes: [String] = [
        "valuenable.in",
        "google.com",
        "google.co.in",
        "googleapis.com",
        "gstatic.com",
        "googleusercontent.com",
        "ggpht.com",
        "googlemail.com",
        "google.co"
    ]

    public static func isHostAllowed(_ host: String?) -> Bool {
        guard let host = host?.lowercased(), !host.isEmpty else { return false }

        return allowedDomainSuffixes.contains { suffix in
            host == suffix || host.hasSuffix("." + suffix)
        }
    }

    // Kept as a no-op for source compatibility with older code.
    // Google authentication requests must NOT be modified with custom headers.
    public static func applyDomainRestrictionHeaders(to request: inout URLRequest) {
        // Intentionally empty.
    }
}
