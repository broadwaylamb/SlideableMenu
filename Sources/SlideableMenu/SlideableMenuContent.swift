import SwiftUI

@MainActor
public protocol SlideableMenuContent<Value> {
    associatedtype Value: Hashable
    associatedtype IdentifiedView: View
    associatedtype Item: View

    var value: Value { get }

    func identifiedView() -> IdentifiedView

    func labelView(isSelected: Binding<Bool>) -> Item

    var isModal: Bool { get }
}
