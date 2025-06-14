import SwiftUI

struct TagView <Content: View>: View {
    let content: Content

    @Environment(\.backgroundStyle)
    var backgroundStyle

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
        .fixedSize()
        .foregroundStyle(.white)
        .backgroundStyle(.clear)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundStyle ?? AnyShapeStyle(.white), in: Capsule())
    }
}

extension TagView where Content == Text {
    init(_ text: String) {
        self.init { Text(text) }
    }
}

extension TagView where Content == Label<Text, Image> {
    init(_ text: String, systemImage: String) {
        self.init { Label(text, systemImage: systemImage) }
    }
}
