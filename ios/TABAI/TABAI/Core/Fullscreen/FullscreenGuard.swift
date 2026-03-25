import SwiftUI

struct FullscreenGuardModifier<Background: View>: ViewModifier {
    let background: Background
    let debugBorder: Bool

    func body(content: Content) -> some View {
        ZStack {
            background
                .ignoresSafeArea()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(
            debugBorder
                ? Rectangle().stroke(Color.red.opacity(0.8), lineWidth: 2)
                : nil
        )
    }
}

extension View {
    func taiFullscreen<Background: View>(debugBorder: Bool = false, @ViewBuilder background: () -> Background) -> some View {
        modifier(FullscreenGuardModifier(background: background(), debugBorder: debugBorder))
    }
}
