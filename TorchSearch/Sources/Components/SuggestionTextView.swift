import SwiftUI

/// Renders the two parts of text side by side:
///   "How to make"  (white, what the user typed)
///   "an excuse"    (faded white, the suggestion)
///
/// Also measures the width of the typed text so we know exactly
/// where to put the torch glow (at the cursor position).
struct SuggestionTextView: View {
    let typedText: String
    let suggestion: String

    /// Called whenever the typed text width changes,
    /// so the parent can position the torch glow at the cursor.
    var onCursorXChange: ((CGFloat) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // ── The bright white text the user typed ──
            Text(typedText)
                .foregroundStyle(.white)
                .background(
                    // This invisible GeometryReader measures the width of the typed text.
                    // That width = where the cursor sits = where the torch glow goes.
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

            // ── The faded suggestion text ──
            if !suggestion.isEmpty {
                Text(suggestion)
                    .foregroundStyle(.white.opacity(0.3))
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
            }
        }
        // Figma specs: DM Sans, 20px, weight 400, line-height 90%, letter-spacing -1px
        .font(.custom("DMSans-Regular", size: 20))
        .tracking(-1)
        .lineSpacing(20 * 0.9 - 20) // 90% line-height
        .lineLimit(1)
    }
}
