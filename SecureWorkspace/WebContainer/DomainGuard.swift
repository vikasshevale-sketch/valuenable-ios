import Foundation
public final class DomainGuard {
    public static let allowedCompanyDomain = "valuenable.in"
    public static let googleAllowedDomainsHeader = "X-GoogApps-Allowed-Domains"
    
    /// Comprehensive whitelist for Google Workspace, CDNs, APIs, and Company domain
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
        
        for suffix in allowedDomainSuffixes {
            if host == suffix || host.hasSuffix("." + suffix) {
                return true
            }
        }
        return false
    }
    
    public static func applyDomainRestrictionHeaders(to request: inout URLRequest) {
        guard let host = request.url?.host?.lowercased() else { return }
        if host.contains("google") {
            request.setValue(allowedCompanyDomain, forHTTPHeaderField: googleAllowedDomainsHeader)
        }
    }
}
