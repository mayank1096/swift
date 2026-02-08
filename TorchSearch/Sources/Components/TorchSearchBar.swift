import SwiftUI

/// The main search bar component that combines everything:
/// 1. An invisible TextField (handles keyboard + typing)
/// 2. Visible styled text (white typed text + gray suggestion)
/// 3. The torch glow trapezoid (positioned at the cursor)
/// 4. The dark rounded-rect container with border + shadows
///
/// Figma specs:
///   Size: 357 × 67 pt
///   Border-radius: 12
///   Border: 1px solid rgba(255, 255, 255, 0.14)
///   Background: #0D0D0D
///   Box-shadow: 0 18px 54px rgba(0,0,0,0.70), inset 0 0 40px rgba(0,0,0,0.30)
struct TorchSearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            // ── Layer 1: The torch glow (behind everything) ──
            // Only shows AFTER 100ms debounce + suggestion found (not while typing)
            // cursorX + 20 accounts for the 20pt left padding on the text
            TorchGlowView(
                cursorX: viewModel.cursorX + 20,
                isActive: viewModel.showSuggestion
            )

            // ── Layer 2: The visible text (what the user actually sees) ──
            // Gray suggestion text only appears when showSuggestion is true
            SuggestionTextView(
                typedText: viewModel.searchText,
                suggestion: viewModel.showSuggestion ? viewModel.suggestionSuffix : "",
                onCursorXChange: { x in
                    viewModel.cursorX = x
                }
            )
            .padding(.leading, 20)

            // ── Layer 3: The invisible TextField (handles actual typing) ──
            TextField("", text: $viewModel.searchText, prompt: searchPrompt)
                .foregroundStyle(.clear)                // hide its text rendering
                .tint(Color(red: 1.0, green: 0.467, blue: 0.0)) // orange cursor (#FF7700)
                .font(.custom("DMSans-Regular", size: 20))
                .tracking(-1)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.leading, 20)
                .padding(.trailing, 20)

        }
        .frame(height: 67)
        .frame(maxWidth: .infinity)
        .background(
            // ── The dark container ──
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.051, green: 0.051, blue: 0.051)) // #0D0D0D
        )
        .overlay(
            // ── The subtle white border ──
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // ── Outer shadow: 0 18px 54px rgba(0,0,0,0.70) ──
        .shadow(color: .black.opacity(0.70), radius: 27, x: 0, y: 18)
        // Tap anywhere on the bar to focus
        .onTapGesture { isFocused = true }
        // Accept suggestion on swipe right
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 50 {
                        viewModel.acceptSuggestion()
                    }
                }
        )
    }

    /// Placeholder text shown when the field is empty.
    private var searchPrompt: Text {
        Text("Search anything...")
            .foregroundStyle(.white.opacity(0.3))
            .font(.custom("DMSans-Regular", size: 20))
    }
}
