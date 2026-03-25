import SwiftUI

struct LoadingDotsView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 6, height: 6)
                    .scaleEffect(1 + sin(phase + CGFloat(index)) * 0.2)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}
