import UIKit
import SwiftUI
public final class SecureContainerView: UIView {
    
    private let secureTextField = UITextField()
    private var secureContainer: UIView?
    
    public init(contentView: UIView) {
        super.init(frame: .zero)
        setupSecureContainer(with: contentView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSecureContainer(with contentView: UIView) {
        #if targetEnvironment(simulator)
        // In Simulator/Appetize, attach directly so browser stream is visible
        addSubview(contentView)
        contentView.pinToSuperview()
        #else
        // On Real iPhones, enforce hardware DRM canvas to black out screenshots & recordings
        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        addSubview(secureTextField)
        
        secureTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureTextField.topAnchor.constraint(equalTo: topAnchor),
            secureTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
            secureTextField.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureTextField.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // The internal secure canvas subview is only materialized once the
        // field has gone through a layout pass. Force that pass now, or
        // `subviews.first` can be nil on first run and we'd silently fall
        // through to the UNPROTECTED path below, defeating the screenshot
        // blackout entirely without any error or log.
        secureTextField.layoutIfNeeded()
        
        guard let textCanvasView = secureTextField.subviews.first else {
            assertionFailure("SecureContainerView: secure canvas subview unavailable — screenshot/recording protection is NOT active for this content.")
            addSubview(contentView)
            contentView.pinToSuperview()
            return
        }
        
        self.secureContainer = textCanvasView
        textCanvasView.isUserInteractionEnabled = true
        textCanvasView.addSubview(contentView)
        contentView.pinToSuperview()
        #endif
    }
}
public struct SecureSwiftUIView<Content: View>: UIViewControllerRepresentable {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        let containerController = UIViewController()
        let secureView = SecureContainerView(contentView: hostingController.view)
        
        containerController.addChild(hostingController)
        containerController.view.addSubview(secureView)
        secureView.pinToSuperview()
        hostingController.didMove(toParent: containerController)
        
        return containerController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
extension UIView {
    func pinToSuperview() {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
    }
}
