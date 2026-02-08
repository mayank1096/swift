import SwiftUI

/// The main screen of the app.
///
/// Figma specs:
///   Background: textured dark image (added to Assets as "Background")
///   Title: "Search anything on the web"
///     - "Search " + "on the web" → DM Sans Medium 34px, -1.7px tracking, 110% line-height
///     - "anything" → Playfair Display Italic 34px
struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            // ── Full-screen textured background image ──
            // Add your background image to Assets.xcassets as "Background"
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            // ── Content ──
            VStack(spacing: 24) {
                Spacer()

                // ── Title with mixed fonts ──
                // "Search " in DM Sans Medium, "anything" in Playfair Display Italic,
                // "\non the web" in DM Sans Medium
                titleText
                    .frame(width: 254)

                // ── Search bar ──
                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 18)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Builds the title with mixed fonts using AttributedString.
    /// "Search " → DM Sans Medium 34px
    /// "anything" → Playfair Display Italic 34px
    /// "\non the web" → DM Sans Medium 34px
    private var titleText: some View {
        (
            Text("Search ")
                .font(.custom("DMSans-Medium", size: 34))
            +
            Text("anything")
                .font(.custom("PlayfairDisplay-Italic", size: 34))
            +
            Text("\non the web")
                .font(.custom("DMSans-Medium", size: 34))
        )
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .tracking(-1.7)
        .lineSpacing(34 * 0.1) // 110% line-height = 10% extra
    }
}

#Preview {
    ContentView()
}
