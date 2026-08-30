import WebKit

struct WebSecurityScripts {
    static var copyProtectionScript: WKUserScript {
        let script = """
        (function() {
            // Prevent text selection and touch callouts globally
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = '* { -webkit-user-select: none !important; -webkit-touch-callout: none !important; user-select: none !important; }';
            document.getElementsByTagName('head')[0].appendChild(style);
            
            // Block copy, cut, drag, and context menu events
            ['copy', 'cut', 'dragstart', 'contextmenu'].forEach(function(eventType) {
                document.addEventListener(eventType, function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    return false;
                }, true);
            });
        })();
        """
        return WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }
}
