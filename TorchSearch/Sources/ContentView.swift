import SwiftUI

/// The main screen of the app.
///
/// Figma specs:
///   Background: linear-gradient(173deg, #242424 -17.8%, #151515 60.66%)
///   Title: "Search anything\non the web" — white, centered
///   Search bar: horizontally padded, positioned below the title
struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            // ── Full-screen gradient background ──
            // 173deg ≈ almost straight down, slightly tilted.
            // In SwiftUI, we approximate with top-leading → bottom-trailing.
            LinearGradient(
                colors: [
                    Color(red: 0.141, green: 0.141, blue: 0.141), // #242424
                    Color(red: 0.082, green: 0.082, blue: 0.082), // #151515
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.6) // gradient hits #151515 at ~60%
            )
            .ignoresSafeArea()

            // ── Content ──
            VStack(spacing: 24) {
                Spacer()

                // ── Title ──
                Text("Search anything\non the web")
                    .font(.custom("DMSans-Regular", size: 32))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // ── Search bar ──
                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 18)

                Spacer()
                Spacer() // push content toward upper-third of screen
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
