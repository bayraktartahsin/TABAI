import SwiftUI

struct NoiseOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 6
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    let opacity = Double((x + y).truncatingRemainder(dividingBy: 10)) / 100
                    context.fill(Path(rect), with: .color(.white.opacity(opacity)))
                    y += step
                }
                x += step
            }
        }
        .blendMode(.softLight)
    }
}
