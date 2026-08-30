import Foundation

struct DomainGuard {
    static let allowedDomain = "valuenable.in"
    
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
        
        if host == allowedDomain || host.hasSuffix("." + allowedDomain) {
            return true
        }
        
        return allowedGoogleOAuthDomains.contains { allowedHost in
            host == allowedHost || host.hasSuffix("." + allowedHost)
        }
    }
}