import SwiftUI

struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            // Full-screen textured background image
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title: "Search anything\non the web"
                // "Search " and "on the web" in DM Sans Medium
                // "anything" in Playfair Display Italic
                titleText

                // Search bar
                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 18)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var titleText: some View {
        // "Search anything" on line 1, "on the web" on line 2
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Text("Search")
                    .font(.custom("DMSans-Medium", size: 34))
                Text("anything")
                    .font(.custom("PlayfairDisplay-MediumItalic", size: 34))
                    .italic()
            }
            Text("on the web")
                .font(.custom("DMSans-Medium", size: 34))
        }
        .foregroundStyle(.white)
        .tracking(-1.7)
    }
}

#Preview {
    ContentView()
}
