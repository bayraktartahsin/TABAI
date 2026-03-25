import SwiftUI

struct GradientBackground: View {
    var body: some View {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
        })
        .ignoresSafeArea()
    }
}
