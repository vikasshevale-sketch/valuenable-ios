import UIKit
import QuickLook

class SecurePreviewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    private var fileURL: URL?

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreview()
    }

    private func setupPreview() {
        let previewVC = QLPreviewController()
        previewVC.dataSource = self
        previewVC.delegate = self
        
        addChild(previewVC)
        view.addSubview(previewVC.view)
        previewVC.view.frame = view.bounds
        previewVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewVC.didMove(toParent: self)
        
        navigationItem.rightBarButtonItems = nil
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return fileURL != nil ? 1 : 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return (fileURL as QLPreviewItem?) ?? (NSURL() as QLPreviewItem)
    }
}