import SwiftUI

/// Animated TABAI brain logo — the brain image colors flow like Perplexity's logo.
/// Uses the brain PNG as a mask with a rotating gradient behind it.
struct AnimatedBrandLogo: View {
    var size: CGFloat = 72
    @State private var gradientPhase: CGFloat = 0

    private let brandColors: [Color] = [
        Color(red: 0.20, green: 0.40, blue: 1.0),   // Blue
        Color(red: 0.45, green: 0.25, blue: 0.95),   // Indigo
        Color(red: 0.70, green: 0.20, blue: 0.75),   // Purple
        Color(red: 0.90, green: 0.40, blue: 0.50),   // Pink
        Color(red: 0.95, green: 0.60, blue: 0.25),   // Orange
        Color(red: 0.95, green: 0.80, blue: 0.30),   // Gold
        Color(red: 0.20, green: 0.40, blue: 1.0),    // Back to blue
    ]

    var body: some View {
        // Flowing gradient masked by the brain shape
        AngularGradient(
            colors: brandColors,
            center: .center,
            angle: .degrees(gradientPhase)
        )
        .frame(width: size, height: size)
        .mask(
            Image("TAILogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        )
        .onAppear {
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                gradientPhase = 360
            }
        }
    }
}

/// Animated "TABAI" text with flowing gradient — matches the logo style
struct AnimatedBrandText: View {
    var fontSize: CGFloat = 20
    @State private var gradientPhase: CGFloat = 0

    private let brandColors: [Color] = [
        Color(red: 0.20, green: 0.40, blue: 1.0),
        Color(red: 0.45, green: 0.25, blue: 0.95),
        Color(red: 0.70, green: 0.20, blue: 0.75),
        Color(red: 0.95, green: 0.60, blue: 0.25),
        Color(red: 0.95, green: 0.80, blue: 0.30),
        Color(red: 0.20, green: 0.40, blue: 1.0),
    ]

    var body: some View {
        LinearGradient(
            colors: brandColors,
            startPoint: gradientStart,
            endPoint: gradientEnd
        )
        .frame(height: fontSize * 1.3)
        .mask(
            Text("TABAI")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .tracking(1.5)
        )
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                gradientPhase = 1
            }
        }
    }

    private var gradientStart: UnitPoint {
        UnitPoint(x: -1 + gradientPhase * 3, y: 0.5)
    }

    private var gradientEnd: UnitPoint {
        UnitPoint(x: gradientPhase * 3, y: 0.5)
    }
}

/// Compact logo for headers — small, no animation
struct BrandLogoMark: View {
    var size: CGFloat = 24

    var body: some View {
        Image("TAILogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
