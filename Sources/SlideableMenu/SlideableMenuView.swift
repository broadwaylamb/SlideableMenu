import SwiftUI

public struct SlideableMenuView<Value: Hashable, Rows, SideMenu: View, Content>: View {
    @StateObject private var viewModel: ViewModel<Value>
    private let sideMenu: (SlideableMenuItems<Rows>) -> SideMenu
    private let rows: Rows
    private let content: Content

    public init(
        selection: Binding<Value>,
        @SideMenuContentBuilder<Value> _ items: () -> SideMenuContentBuilderResult<Value, Rows, Content>,
        @ViewBuilder sideMenu: @MainActor @escaping (SlideableMenuItems<Rows>) -> SideMenu,
    ) {
        let result = items()
        _viewModel = StateObject(wrappedValue: ViewModel(indices: result.indices, selection: selection))
        rows = result.labelTuple
        content = result.contentTuple
        self.sideMenu = sideMenu
    }

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.isSlideableMenuFixed) private var isSlideableMenuFixed
    @Environment(\.slideableMenuWidth) private var slideableMenuWidth

    @GestureState private var delta: CGFloat = 0

    private func currentView(alwaysShowMenu: Bool, index: Int) -> some View {
        ExtractSubviews(from: TupleView(content)) { children in
            children[index]
        }
    }

    private var start: CGFloat {
        viewModel.isMenuShown ? slideableMenuWidth : 0
    }

    private func contentOffset() -> CGFloat {
        if isSlideableMenuFixed {
            return slideableMenuWidth
        }
        if /*!viewModel.navigationPath.isEmpty &&*/ !viewModel.isMenuShown && delta < 25 {
            // Prevent conflicting with the native "swipe back from left edge"
            // gesture.
            return start
        }
        return start + delta
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($delta) { value, dragging, _ in
                let slideableMenuWidth = self.slideableMenuWidth
                var translationWidth = value.translation.width
                if layoutDirection == .rightToLeft {
                    translationWidth.negate()
                }
                let start = self.start
                let newOffset = start + translationWidth
                if newOffset < 0 {
                    return
                }
                if newOffset < slideableMenuWidth {
                    dragging = translationWidth
                } else {
                    // Resist dragging too far right
                    let springOffset = newOffset - slideableMenuWidth
                    dragging = slideableMenuWidth - start + springOffset * 0.1
                }
            }
            .onEnded { value in
                var velocity = value.velocity.width
                if layoutDirection == .rightToLeft {
                    velocity.negate()
                }
                viewModel.isMenuShown = velocity >= 0
            }
    }

    public var body: some View {
        GeometryReader { proxy in
            let isSlideableMenuFixed = self.isSlideableMenuFixed
            let viewportWidth = proxy.size.width
            let contentWidth = isSlideableMenuFixed
                ? viewportWidth - slideableMenuWidth
                : viewportWidth
            let contentOffset = self.contentOffset()
            ZStack(alignment: .topLeading) {
                sideMenu(SlideableMenuItems(items: TupleView(rows)))
                    .environmentObject(viewModel)
                currentView(
                    alwaysShowMenu: isSlideableMenuFixed,
                    index: viewModel.currentViewIndex,
                )
                .overlay {
                    if viewModel.isMenuShown {
                        Color.black.opacity(0.0001)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.isMenuShown = false
                            }
                    }
                }
                .offset(x: contentOffset)
                .frame(maxWidth: contentWidth)
                .animation(.interactiveSpring(extraBounce: 0), value: contentOffset)
            }
            .environment(
                \.toggleSlideableMenu,
                 ToggleSlideableMenuAction {
                     viewModel.isMenuShown.toggle()
                 }
            )
            .gesture(dragGesture, isEnabled: !isSlideableMenuFixed)
            .sheet(isPresented: $viewModel.isModallyPresented) {
                currentView(alwaysShowMenu: isSlideableMenuFixed, index: viewModel.currentModalViewIndex!)
            }
        }
    }
}

@available(iOS 16.0, *)
private struct TestItem<Value: Hashable>: SideMenuContent {
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
