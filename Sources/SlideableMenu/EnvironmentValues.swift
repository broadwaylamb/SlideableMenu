import SwiftUI

extension EnvironmentValues {
    @Entry public var slideableMenuWidth: CGFloat = 276
    @Entry public var isSlideableMenuFixed = false
    @Entry public var toggleSlideableMenu = ToggleSlideableMenuAction {}
}

extension View {
    public func slideableMenuWidth(_ value: CGFloat) -> some View {
        environment(\.slideableMenuWidth, value)
    }

    public func fixSlideableMenu(_ alwaysShow: Bool = true) -> some View {
        environment(\.isSlideableMenuFixed, alwaysShow)
    }
}

public struct ToggleSlideableMenuAction {
    let handler: () -> Void
    func callAsFunction() {
        handler()
    }
}
