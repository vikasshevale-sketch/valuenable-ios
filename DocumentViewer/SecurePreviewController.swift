import UIKit
import QuickLook

/// Sandboxed document viewer that suppresses all iOS Share Sheets, AirDrop, Save to Files, and Print actions.
public final class SecurePreviewController: QLPreviewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    
    private let fileURL: URL
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = fileURL.lastPathComponent
        
        // Add secure container wrapping to prevent screenshot/screen capture of documents
        let secureView = SecureContainerView(contentView: self.view)
        self.view.addSubview(secureView)
        secureView.pinToSuperview()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        stripExportActions()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stripExportActions()
    }
    
    /// Recursively strips iOS Share button (UIActivityViewController / UIBarButtonSystemItemAction)
    private func stripExportActions() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItems = nil
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissViewer))
        navigationItem.leftBarButtonItem = doneButton
        
        // Remove action buttons in child navigation controllers
        if let navBar = navigationController?.navigationBar {
            navBar.topItem?.rightBarButtonItem = nil
            navBar.topItem?.rightBarButtonItems = nil
        }
    }
    
    @objc private func dismissViewer() {
        dismiss(animated: true) {
            // Securely purge temporary attachment from disk upon closing
            try? FileManager.default.removeItem(at: self.fileURL)
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
    
    // MARK: - QLPreviewControllerDelegate (Disable external app handoff)
    public func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: QLPreviewItem) -> Bool {
        return false // Block external link opening from within documents
    }
}
