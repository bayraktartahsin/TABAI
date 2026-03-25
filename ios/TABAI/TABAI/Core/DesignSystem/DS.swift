import SwiftUI
import UIKit

enum DS {
    enum Colors {
        static let backgroundTop = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1)
                : UIColor(red: 0.95, green: 0.97, blue: 0.995, alpha: 1)
        })
        static let backgroundBottom = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.03, green: 0.04, blue: 0.07, alpha: 1)
                : UIColor(red: 0.90, green: 0.94, blue: 0.985, alpha: 1)
        })
        static let accent = Color(red: 0.35, green: 0.80, blue: 0.70)
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
        static let glassStroke = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.14)
                : UIColor.black.withAlphaComponent(0.08)
        })
        static let cardBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.14, blue: 0.20, alpha: 0.78)
                : UIColor.white.withAlphaComponent(0.84)
        })
        static let fieldBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.white.withAlphaComponent(0.78)
        })
    }

    enum Layout {
        static let cornerRadius: CGFloat = 24
        static let fieldCornerRadius: CGFloat = 14
        static let horizontalPadding: CGFloat = 24
        static let verticalSpacing: CGFloat = 16
        static let cardPadding: CGFloat = 24
    }

    enum Typography {
        static let title = Font.custom("Avenir Next", size: 34).weight(.semibold)
        static let subtitle = Font.custom("Avenir Next", size: 16).weight(.medium)
        static let body = Font.custom("Avenir Next", size: 15)
        static let button = Font.custom("Avenir Next", size: 17).weight(.semibold)
    }

    enum Motion {
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let quickSpring = Animation.spring(response: 0.28, dampingFraction: 0.82)
        static let fade = Animation.easeInOut(duration: 0.2)
    }
}

struct SkeletonBlock: View {
    let height: CGFloat
    let width: CGFloat?
    var cornerRadius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(DS.Colors.fieldBackground.opacity(0.85))
            .frame(width: width, height: height)
            .modifier(SkeletonShimmerModifier())
            .accessibilityHidden(true)
    }
}

private struct SkeletonShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.9

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [
                            .white.opacity(0.0),
                            .white.opacity(0.14),
                            .white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(18))
                    .offset(x: phase * max(proxy.size.width, 1) * 1.7)
                }
                .mask(content)
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                    phase = 0.95
                }
            }
    }
}

extension View {
    @ViewBuilder
    func taiSheetChrome() -> some View {
        if #available(iOS 16.4, *) {
            self
                .presentationCornerRadius(28)
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }
}
