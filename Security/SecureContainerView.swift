import UIKit
import SwiftUI

/// `SecureContainerView` embeds any UIView/SwiftUI view hierarchy inside a secure
/// sublayer of an internal `UITextField` whose `isSecureTextEntry` property is `true`.
///
/// Under the iOS rendering pipeline, secure text entry fields are rendered via a dedicated
/// private DRM surface. When iOS takes a screenshot, captures screen recordings, or streams
/// via AirPlay/Zoom/Teams screen share, this surface is completely blacked out by the OS compositor.
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
        // Configure hidden secure textfield
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
        
        // Find the secure canvas container inside the secure textfield subviews
        // On iOS, the first subview of UITextField's layer or canvas acts as the DRM protected layer
        guard let textCanvasView = secureTextField.subviews.first else {
            // Fallback: Embed directly if canvas hierarchy is unavailable
            addSubview(contentView)
            contentView.pinToSuperview()
            return
        }
        
        self.secureContainer = textCanvasView
        textCanvasView.isUserInteractionEnabled = true
        textCanvasView.addSubview(contentView)
        contentView.pinToSuperview()
    }
}

// MARK: - SwiftUI Wrapper for SecureContainerView
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
