import Combine
import SwiftUI
import UIKit

internal final class SlideableMenuViewController<Menu: View, Content: View>: UIViewController {
    private let menuViewController: UIHostingController<Menu>
    private let contentViewController: UIHostingController<Content>
    private let isMenuRevealedPublisher: PassthroughSubject<Bool, Never>
    private var cancellables = Set<AnyCancellable>()

    private func updateUserInteractionForContent() {
        touchEventsCatcher.isUserInteractionEnabled = !isMenuFixed && isMenuRevealed
    }

    private var isMenuRevealed = false {
        didSet {
            updateUserInteractionForContent()
        }
    }

    private var isMenuFixed = false {
        didSet {
            updateUserInteractionForContent()
        }
    }

    private var menuWidth: CGFloat = 0

    init(isMenuRevealedPublisher: PassthroughSubject<Bool, Never>, menu: Menu, content: Content) {
        self.isMenuRevealedPublisher = isMenuRevealedPublisher
        menuViewController = UIHostingController(rootView: menu)
        contentViewController = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)

        isMenuRevealedPublisher
            .sink { [unowned self] newValue in
                self.isMenuRevealed = newValue
                self.moveMenuToFinalPositionAnimated()
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func update(isMenuFixed: Bool, menuWidth: CGFloat, menu: Menu? = nil, content: Content? = nil) {
        if let menu {
            menuViewController.rootView = menu
        }
        if let content {
            contentViewController.rootView = content
        }
        self.isMenuFixed = isMenuFixed
        self.menuWidth = menuWidth
    }

    /// The view behind the content view to avoid passing through touch events on the content view
    /// when the menu is revealed and `contentViewController.view.isUserInteractionEnabled` is
    /// `false`.
    private let touchEventsCatcher = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(menuViewController)
        view.addSubview(menuViewController.view)
        menuViewController.view.frame = view.bounds
        menuViewController.didMove(toParent: self)

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.view.frame = view.bounds
        contentViewController.didMove(toParent: self)

        view.addSubview(touchEventsCatcher)
        touchEventsCatcher.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        )

        view.addGestureRecognizer(
            UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        )
    }

    override func viewWillLayoutSubviews() {
        menuViewController.view.frame = view.bounds
        if isMenuFixed {
            var x = menuWidth
            if traitCollection.layoutDirection == .rightToLeft {
                x = 0
            }
            contentViewController.view.frame = CGRect(
                x: x,
                y: 0,
                width: view.bounds.width - menuWidth,
                height: view.bounds.height,
            )

            touchEventsCatcher.frame = contentViewController.view.frame
        } else {
            contentViewController.view.frame = view.bounds
            updateContentPosition()
        }
    }

    private var panDelta: CGFloat = 0

    private var start: CGFloat {
        (isMenuRevealed || isMenuFixed) ? menuWidth : 0
    }

    private func updateContentPosition() {
        var centerOffset = start + panDelta + contentViewController.view.frame.width / 2
        if traitCollection.layoutDirection == .rightToLeft {
            centerOffset = view.bounds.width - centerOffset
        }
        contentViewController.view.center.x = centerOffset
        touchEventsCatcher.frame = contentViewController.view.frame
    }

    @objc private func panGesture(_ sender: UIPanGestureRecognizer) {
        if isMenuFixed {
            return
        }
        let menuWidth = self.menuWidth
        var translationX = sender.translation(in: view).x
        if traitCollection.layoutDirection == .rightToLeft {
            translationX.negate()
        }
        let start = self.start
        let newOffset = start + translationX
        if newOffset >= 0 {
            if newOffset < menuWidth {
                panDelta = translationX
            } else {
                // Resist dragging too far right
                let springOffset = newOffset - menuWidth
                panDelta = menuWidth - start + springOffset * 0.1
            }
        }

        switch sender.state {
        case .ended, .cancelled, .failed:
            panDelta = 0
        default:
            break
        }

        if sender.state == .ended {
            var velocity = sender.velocity(in: view).x
            if traitCollection.layoutDirection == .rightToLeft {
                velocity.negate()
            }
            isMenuRevealed = velocity >= 0
            moveMenuToFinalPositionAnimated(gestureVelocity: velocity)
        } else {
            updateContentPosition()
        }
    }

    private func moveMenuToFinalPositionAnimated(gestureVelocity: CGFloat = 0) {
        var animationVelocity: CGFloat = 0
        let xDistance = start - contentViewController.view.center.x
        if xDistance != 0 {
            animationVelocity = gestureVelocity / xDistance
        }
        let timingParameters = UISpringTimingParameters(
            dampingRatio: 1,
            initialVelocity: CGVector(dx: animationVelocity, dy: 0),
        )

        let animator = UIViewPropertyAnimator(
            duration: 0.15,
            timingParameters: timingParameters,
        )
        animator.addAnimations {
            self.updateContentPosition()
        }
        animator.startAnimation()
    }

    @objc private func tapGesture(_ sender: UITapGestureRecognizer) {
        if isMenuFixed {
            return
        }
        isMenuRevealed = false
        moveMenuToFinalPositionAnimated()
    }
}

internal struct SlideableMenuViewControllerAdaptor<Menu: View, Content: View>: UIViewControllerRepresentable {
    internal let isMenuRevealedPublisher: PassthroughSubject<Bool, Never>
    internal let menu: () -> Menu
    internal let content: () -> Content

    func makeUIViewController(context: Context) -> SlideableMenuViewController<Menu, Content> {
        let vc = SlideableMenuViewController(
            isMenuRevealedPublisher: isMenuRevealedPublisher,
            menu: menu(),
            content: content(),
        )
        vc.update(
            isMenuFixed: context.environment.isSlideableMenuFixed,
            menuWidth: context.environment.slideableMenuWidth,
        )
        return vc
    }

    func updateUIViewController(
        _ uiViewController: SlideableMenuViewController<Menu, Content>,
        context: Context,
    ) {
        uiViewController.update(
            isMenuFixed: context.environment.isSlideableMenuFixed,
            menuWidth: context.environment.slideableMenuWidth,
            menu: menu(),
            content: content(),
        )
    }
}
