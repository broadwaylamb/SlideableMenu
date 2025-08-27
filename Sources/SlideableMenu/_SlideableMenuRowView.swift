import SwiftUI

public struct _SlideableMenuRowView<Item: SideMenuContent>: View {
    internal let item: Item

    @EnvironmentObject private var viewModel: ViewModel<Item.Value>

    public var body: Item.Item {
        return item.labelView(
            isSelected: Binding {
                viewModel.currentSelection == item.value
            } set: { isSelected in
                if isSelected {
                    viewModel.selectItem(item.value, isModal: item.isModal)
                }
            }
        )
    }
}
