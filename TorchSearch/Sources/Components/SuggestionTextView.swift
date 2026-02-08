import SwiftUI

struct SuggestionTextView: View {
    let typedText: String
    let suggestion: String

    var onCursorXChange: ((CGFloat) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // The bright white text the user typed
            Text(typedText)
                .foregroundStyle(.white)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                onCursorXChange?(geo.size.width)
                            }
                            .onChange(of: typedText) { _, _ in
                                onCursorXChange?(geo.size.width)
                            }
                    }
                )

            // The faded suggestion text with slide-up animation
            // Each time `suggestion` changes, the old text slides up and fades out,
            // and the new text slides in from below.
            if !suggestion.isEmpty {
                Text(suggestion)
                    .foregroundStyle(.white.opacity(0.3))
                    .id(suggestion) // forces SwiftUI to treat each suggestion as a new view
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .animation(.easeInOut(duration: 0.3), value: suggestion)
            }
        }
        // Figma: DM Sans, 18px, weight 400, letter-spacing -0.9px
        .font(.custom("DMSans-Regular", size: 18))
        .tracking(-0.9)
        .lineLimit(1)
        .clipped() // clip the sliding text so it doesn't overflow
        .animation(.easeInOut(duration: 0.3), value: suggestion)
    }
}
