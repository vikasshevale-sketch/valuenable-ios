import UIKit
import QuickLook

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
    
    private func stripExportActions() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItems = nil
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissViewer))
        navigationItem.leftBarButtonItem = doneButton
        
        if let navBar = navigationController?.navigationBar {
            navBar.topItem?.rightBarButtonItem = nil
            navBar.topItem?.rightBarButtonItems = nil
        }
    }
    
    @objc private func dismissViewer() {
        dismiss(animated: true) {
            try? FileManager.default.removeItem(at: self.fileURL)
        }
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
    
    public func previewController(_ controller: QLPreviewController, shouldOpen url: URL, for item: QLPreviewItem) -> Bool {
        return false
    }
}
