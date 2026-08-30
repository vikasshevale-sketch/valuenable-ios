import Foundation

struct DomainGuard {
    static let allowedDomain = "valuenable.in"
    
    // Whitelisted authentication & infrastructure endpoints required for Google Workspace login
    static let allowedGoogleOAuthDomains: Set<String> = [
        "accounts.google.com",
        "ssl.gstatic.com",
        "accounts.youtube.com",
        "myaccount.google.com",
        "login.m.google.com",
        "apis.google.com",
        "oauth2.googleapis.com"
    ]
    
    static func isDomainAllowed(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        
        // 1. Allow target domain and subdomains
        if host == allowedDomain || host.hasSuffix("." + allowedDomain) {
            return true
        }
        
        // 2. Allow Google Workspace Authentication Flow Domains
        return allowedGoogleOAuthDomains.contains { allowedHost in
            host == allowedHost || host.hasSuffix("." + allowedHost)
        }
    }
}
