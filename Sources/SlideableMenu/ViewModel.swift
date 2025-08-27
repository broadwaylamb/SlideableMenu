import SwiftUI

internal final class ViewModel<Value: Hashable>: ObservableObject {
    internal let indices: [Value : Int]
    @Published internal var isMenuShown = false
    @Published private(set) internal var currentSelection: Value
    @Binding private var selection: Value
    @Published private(set) internal var currentViewIndex: Int
    @Published private(set) internal var currentModalViewIndex: Int?

    private var lastNonModalSelection: Value

    internal var isModallyPresented: Bool {
        get {
            currentModalViewIndex != nil
        }
        set {
            if !newValue {
                currentModalViewIndex = nil
                currentSelection = lastNonModalSelection
            }
        }
    }

    internal init(indices: [Value : Int], selection: Binding<Value>) {
        self.indices = indices
        _selection = selection
        currentSelection = selection.wrappedValue
        lastNonModalSelection = selection.wrappedValue
        currentViewIndex = indices[selection.wrappedValue] ?? 0
    }

    internal func selectItem(_ newSelection: Value, isModal: Bool) {
        isMenuShown = false
        if isModal {
            lastNonModalSelection = currentSelection
            currentModalViewIndex = indices[newSelection] ?? 0
        } else {
            lastNonModalSelection = newSelection
            currentModalViewIndex = nil
            currentViewIndex = indices[newSelection] ?? 0
        }
        selection = newSelection
        currentSelection = newSelection
    }
}
