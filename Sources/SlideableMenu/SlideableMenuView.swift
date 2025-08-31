import SwiftUI

public struct SlideableMenuView<Value: Hashable, Rows, SideMenu: View, Content>: View {
    @StateObject private var viewModel: ViewModel<Value>
    private let sideMenu: (SlideableMenuItems<Rows>) -> SideMenu
    private let rows: Rows
    private let content: Content

    public init(
        selection: Binding<Value>,
        @SlideableMenuContentBuilder<Value> _ items: () -> SlideableMenuContentBuilder<Value>.Result<Rows, Content>,
        @ViewBuilder sideMenu: @MainActor @escaping (SlideableMenuItems<Rows>) -> SideMenu,
    ) {
        let result = items()
        _viewModel = StateObject(wrappedValue: ViewModel(indices: result.indices, selection: selection))
        rows = result.labelTuple
        content = result.contentTuple
        self.sideMenu = sideMenu
    }

    private func currentView(index: Int) -> some View {
        ExtractSubviews(from: TupleView(content)) { children in
            children[index]
        }
    }

    public var body: some View {
        SlideableMenuViewControllerAdaptor(
            isMenuRevealedPublisher: viewModel.isMenuRevealedPublisher
        ) {
            sideMenu(SlideableMenuItems(items: TupleView(rows)))
                .environmentObject(viewModel)
        } content: {
            currentView(index: viewModel.currentViewIndex)
        }
        .environment(
            \.revealSlideableMenu,
             RevealSlideableMenuAction {
                 viewModel.isMenuRevealedPublisher.send(true)
             }
        )
        .sheet(isPresented: $viewModel.isModallyPresented) {
            currentView(index: viewModel.currentModalViewIndex!)
        }
    }
}

@available(iOS 16.0, *)
private struct TestItem<Value: Hashable>: SlideableMenuContent {
    var value: Value
    var isModal: Bool = false
    var color: Color
    var text: String

    func identifiedView() -> some View {
        ZStack {
            color
                .border(Color.gray, width: 15)
            Text(verbatim: text)
        }
    }

    func labelView(isSelected: Binding<Bool>) -> some View {
        Button {
            isSelected.wrappedValue = true
        } label: {
            Text(verbatim: text)
                .bold(isSelected.wrappedValue)
        }

    }
}


@available(iOS 17.0, *)
#Preview("Collapsible") {
    @Previewable @State var selection = 0
    SlideableMenuView(selection: $selection) {
        TestItem(value: 0, color: .red, text: "Red")
        TestItem(value: 1, color: .green, text: "Green")
        TestItem(value: 2, isModal: true, color: .blue, text: "Blue")
    } sideMenu: { items in
        List {
            items
        }
        .listStyle(.plain)
    }
}


@available(iOS 17.0, *)
#Preview("Fixed") {
    @Previewable @State var selection = 0
    SlideableMenuView(selection: $selection) {
        TestItem(value: 0, color: .red, text: "Red")
        TestItem(value: 1, color: .green, text: "Green")
        TestItem(value: 2, isModal: true, color: .blue, text: "Blue")
    } sideMenu: { items in
        List {
            items
        }
        .listStyle(.plain)
    }
    .fixSlideableMenu()
}
