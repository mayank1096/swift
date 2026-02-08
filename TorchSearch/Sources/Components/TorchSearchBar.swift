import SwiftUI

/// The main search bar component that combines everything:
/// 1. An invisible TextField (handles keyboard + typing)
/// 2. Visible styled text (white typed text + gray suggestion)
/// 3. The torch glow trapezoid (positioned at the cursor)
/// 4. A mic icon on the right
/// 5. The dark rounded-rect container with border + shadows
///
/// Figma specs:
///   Size: 357 × 67 pt
///   Border-radius: 12
///   Border: 1px solid rgba(255, 255, 255, 0.12)
///   Background: #0D0D0D
///   Box-shadow: 0 18px 54px #000, inset 0 0 40px rgba(0,0,0,0.30)
struct TorchSearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            // ── Layer 1: The torch glow (behind everything) ──
            TorchGlowView(
                cursorX: viewModel.cursorX + 20,
                isActive: viewModel.showSuggestion
            )

            // ── Layer 2: The visible text (what the user actually sees) ──
            SuggestionTextView(
                typedText: viewModel.searchText,
                suggestion: viewModel.showSuggestion ? viewModel.suggestionSuffix : "",
                onCursorXChange: { x in
                    viewModel.cursorX = x
                }
            )
            .padding(.leading, 20)
            .padding(.trailing, 56) // leave room for mic icon

            // ── Layer 3: The invisible TextField (handles actual typing) ──
            TextField("", text: $viewModel.searchText, prompt: searchPrompt)
                .foregroundStyle(.clear)
                .tint(Color(red: 1.0, green: 0.467, blue: 0.0)) // #FF7700 cursor
                .font(.custom("DMSans-Regular", size: 18))
                .tracking(-0.9)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.leading, 20)
                .padding(.trailing, 56)

            // ── Layer 4: Mic icon on the right ──
            HStack {
                Spacer()
                micIcon
                    .frame(width: 22, height: 22)
                    .padding(.trailing, 20)
            }
        }
        .frame(height: 67)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.051, green: 0.051, blue: 0.051)) // #0D0D0D
        )
        .overlay(
            // Border: 1px solid rgba(255, 255, 255, 0.12)
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Outer shadow: 0 18px 54px #000
        .shadow(color: .black, radius: 27, x: 0, y: 18)
        .onTapGesture { isFocused = true }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width > 50 {
                        viewModel.acceptSuggestion()
                    }
                }
        )
    }

    /// Placeholder text when field is empty.
    private var searchPrompt: Text {
        Text("Search anything...")
            .foregroundStyle(.white.opacity(0.3))
            .font(.custom("DMSans-Regular", size: 18))
    }

    /// Mic icon drawn from the Figma SVG.
    /// Stroke color: #404040
    private var micIcon: some View {
        Canvas { context, size in
            let scale = size.width / 22.0

            // Mic body (rounded rect path)
            var micBody = Path()
            let capsuleRect = CGRect(
                x: 8.25 * scale, y: 1.833 * scale,
                width: 5.5 * scale, height: 11.917 * scale
            )
            micBody.addRoundedRect(in: capsuleRect, cornerSize: CGSize(width: 2.75 * scale, height: 2.75 * scale))

            // Stand line (bottom)
            var standLine = Path()
            standLine.move(to: CGPoint(x: 11 * scale, y: 17.417 * scale))
            standLine.addLine(to: CGPoint(x: 11 * scale, y: 20.167 * scale))

            // Arc (the U-shape around the mic)
            var arcPath = Path()
            arcPath.move(to: CGPoint(x: 17.416 * scale, y: 9.167 * scale))
            arcPath.addLine(to: CGPoint(x: 17.416 * scale, y: 11 * scale))
            // Approximate the arc with a curve
            arcPath.addQuadCurve(
                to: CGPoint(x: 11 * scale, y: 17.417 * scale),
                control: CGPoint(x: 17.416 * scale, y: 15 * scale)
            )
            arcPath.addQuadCurve(
                to: CGPoint(x: 4.583 * scale, y: 11 * scale),
                control: CGPoint(x: 4.583 * scale, y: 15 * scale)
            )
            arcPath.addLine(to: CGPoint(x: 4.583 * scale, y: 9.167 * scale))

            let strokeStyle = StrokeStyle(lineWidth: 2 * scale, lineCap: .round, lineJoin: .round)
            let color = Color(red: 0.251, green: 0.251, blue: 0.251) // #404040

            context.stroke(micBody, with: .color(color), style: strokeStyle)
            context.stroke(standLine, with: .color(color), style: strokeStyle)
            context.stroke(arcPath, with: .color(color), style: strokeStyle)
        }
    }
}
