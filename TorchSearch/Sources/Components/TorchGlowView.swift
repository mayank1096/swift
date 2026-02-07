import SwiftUI

/// The orange flashlight/torch glow that appears at the cursor position.
///
/// From the Figma SVG, the shape is a **trapezoid**:
/// - Narrow on the LEFT (at the cursor) — about 28pt tall
/// - Fans out WIDER to the RIGHT — about 66pt tall
/// - Like a flashlight beam spreading forward
///
/// It's filled with a linear gradient: #FF7700 (orange) → #0D0D0D (background dark)
/// and blurred 3px.
///
/// The `cursorX` parameter tells us where to position it horizontally.
struct TorchGlowView: View {
    /// Where the cursor is (in points from the left edge of the search bar content area)
    let cursorX: CGFloat

    /// Whether the glow should be visible (only when the user is typing / field is focused)
    let isActive: Bool

    var body: some View {
        if isActive {
            Canvas { context, size in
                // ── Build the trapezoid shape ──
                // Narrow on the left (at cursor), fans out to the right.
                //
                // Figma SVG reference:
                //   Narrow end: y = 24.5 to y = 53   → height ≈ 28pt
                //   Wide end:   y = 6    to y = 72.5  → height ≈ 66pt
                //   Width of shape: ~62pt
                //
                // We'll scale proportionally to look right in our 67pt-tall search bar.

                let glowWidth: CGFloat = 70
                let narrowHalfHeight: CGFloat = 14  // half of 28pt
                let wideHalfHeight: CGFloat = 33    // half of 66pt
                let centerY = size.height / 2

                // Position: the narrow end starts at cursorX,
                // the wide end extends to cursorX + glowWidth
                let left = cursorX
                let right = left + glowWidth

                var path = Path()
                path.move(to: CGPoint(x: left, y: centerY - narrowHalfHeight))    // top-left
                path.addLine(to: CGPoint(x: right, y: centerY - wideHalfHeight))  // top-right
                path.addLine(to: CGPoint(x: right, y: centerY + wideHalfHeight))  // bottom-right
                path.addLine(to: CGPoint(x: left, y: centerY + narrowHalfHeight)) // bottom-left
                path.closeSubpath()

                // ── Fill with the orange-to-dark gradient ──
                // Figma: linear-gradient(79deg, #F70 -51.56%, #0D0D0D 90.5%)
                let gradient = Gradient(colors: [
                    Color(red: 1.0, green: 0.467, blue: 0.0),  // #FF7700
                    Color(red: 0.051, green: 0.051, blue: 0.051).opacity(0) // #0D0D0D → transparent
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: left - glowWidth * 0.3, y: centerY),
                        endPoint: CGPoint(x: right, y: centerY)
                    )
                )
            }
            // Figma: filter: blur(3px)
            .blur(radius: 3)
            .allowsHitTesting(false) // don't block touches on the text field
            .animation(.easeOut(duration: 0.2), value: cursorX)
        }
    }
}
