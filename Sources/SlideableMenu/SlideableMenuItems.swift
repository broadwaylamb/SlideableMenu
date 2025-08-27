import SwiftUI

public struct SlideableMenuItems<Items>: View {
    internal let items: TupleView<Items>

    public var body: some View {
        items
    }
}
