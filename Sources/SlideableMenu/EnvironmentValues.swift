import SwiftUI

extension EnvironmentValues {
    @Entry public var slideableMenuWidth: CGFloat = 276
    @Entry public var isSlideableMenuFixed = false
    @Entry public var revealSlideableMenu = RevealSlideableMenuAction()
}

extension View {
    public func slideableMenuWidth(_ value: CGFloat) -> some View {
        environment(\.slideableMenuWidth, value)
    }

    public func fixSlideableMenu(_ alwaysShow: Bool = true) -> some View {
        environment(\.isSlideableMenuFixed, alwaysShow)
    }
}

public struct RevealSlideableMenuAction {
    internal let handler: () -> Void

    internal init(handler: @escaping () -> Void = {}) {
        self.handler = handler
    }

    public func callAsFunction() {
        handler()
    }
}
