import Foundation

public final class DomainGuard {
    public static let allowedCompanyDomain = "valuenable.in"
    public static let googleAllowedDomainsHeader = "X-GoogApps-Allowed-Domains"
    
    private static let allowedHosts: Set<String> = [
        "accounts.google.com",
        "mail.google.com",
        "drive.google.com",
        "docs.google.com",
        "calendar.google.com",
        "meet.google.com",
        "chat.google.com",
        "contacts.google.com",
        "myaccount.google.com",
        "admin.google.com",
        "apis.google.com",
        "ssl.gstatic.com",
        "lh3.googleusercontent.com",
        "clients6.google.com"
    ]
    
    public static func isHostAllowed(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        for allowed in allowedHosts {
            if host == allowed || host.hasSuffix("." + allowed) || host.hasSuffix(".google.com") || host.hasSuffix(".googleusercontent.com") || host.hasSuffix(".gstatic.com") {
                return true
            }
        }
        return false
    }
    
    public static func applyDomainRestrictionHeaders(to request: inout URLRequest) {
        guard let host = request.url?.host?.lowercased() else { return }
        if host.contains("google.com") || host.contains("accounts.google.com") {
            request.setValue(allowedCompanyDomain, forHTTPHeaderField: googleAllowedDomainsHeader)
        }
    }
}
