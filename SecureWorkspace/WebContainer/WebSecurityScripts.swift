import WebKit

public struct WebSecurityScripts {
    public static var dlpPreventionScript: WKUserScript {
        let css = """
        * {
            -webkit-touch-callout: none !important;
            -webkit-user-select: none !important;
            user-select: none !important;
        }
        input, textarea, [contenteditable="true"] {
            -webkit-user-select: text !important;
            user-select: text !important;
        }
        """
        
        let js = """
        (function() {
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
            
            document.addEventListener('copy', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, true);
            
            document.addEventListener('cut', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, true);
            
            document.addEventListener('contextmenu', function(e) {
                e.preventDefault();
            }, true);
            
            document.addEventListener('dragstart', function(e) {
                e.preventDefault();
            }, true);
        })();
        """
        
        return WKUserScript(
            source: js,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }
}
