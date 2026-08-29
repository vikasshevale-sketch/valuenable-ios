import WebKit

public struct WebSecurityScripts {
    
    /// UserScript that injects strict CSS to disable iOS touch callouts, text selection, and drag/drop
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
            // 1. Inject CSS Rules
            var style = document.createElement('style');
            style.type = 'text/css';
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
            
            // 2. Block Copy & Cut events on DOM level
            document.addEventListener('copy', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, true);
            
            document.addEventListener('cut', function(e) {
                e.preventDefault();
                e.stopPropagation();
            }, true);
            
            // 3. Block Context Menu (Long press)
            document.addEventListener('contextmenu', function(e) {
                e.preventDefault();
            }, true);
            
            // 4. Block Drag & Drop to external targets
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
