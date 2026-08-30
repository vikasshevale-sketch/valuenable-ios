import UIKit

class SecureContainerView: UIView {
    private let secureTextField = UITextField()
    private var containerView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSecureContainer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSecureContainer()
    }

    private func setupSecureContainer() {
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        
        guard let canvasView = secureTextField.subviews.first else { return }
        
        canvasView.frame = self.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(canvasView)
        self.containerView = canvasView
    }

    func embed(childView: UIView) {
        guard let containerView = containerView else { return }
        childView.frame = containerView.bounds
        childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(childView)
    }
}