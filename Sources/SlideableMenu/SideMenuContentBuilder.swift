import SwiftUI

@resultBuilder
public struct SideMenuContentBuilder<Value: Hashable> {

    // FIXME: Uncomment <Value> when same-type requirements are supported for
    // type parameter packs
    // https://forums.swift.org/t/variadic-types-same-element-requirements-are-not-yet-supported
    @MainActor
    public static func buildBlock<each T: SideMenuContent/*<Value>*/>(
        _ content: repeat each T,
    ) -> SideMenuContentBuilderResult<Value, (repeat _SlideableMenuRowView<each T>), (repeat (each T).IdentifiedView)> {
        var indices = [Value : Int]()
        var i = 0
        for c in repeat each content {
            let value = c.value as! Value
            indices[value] = i
            i += 1
        }

        return SideMenuContentBuilderResult(
            indices: indices,
            labelTuple: (repeat _SlideableMenuRowView(item: each content)),
            contentTuple: (repeat (each content).identifiedView()),
        )
    }
}

public struct SideMenuContentBuilderResult<Value: Hashable, RowTuple, ContentTuple> {
    internal let indices: [Value : Int]
    internal let labelTuple: RowTuple
    internal let contentTuple: ContentTuple
}
