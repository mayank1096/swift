import SwiftUI

/// The orange flashlight/torch glow that appears at the cursor position.
///
/// Updated Figma SVG (106×94):
///   Path: M100 6L6 34V59L100 87.5V6Z
///   Narrow end (left, at cursor): y=34 to y=59 → height = 25pt
///   Wide end (right): y=6 to y=87.5 → height = 81.5pt
///   Width: ~94pt
///
///   Gradient: linear-gradient(87deg, #F70 -10.87%, rgba(13,13,13,0) 87.43%)
///   Inner shadow: 5px 0 7px rgba(255,132,0,0.14) inset
///   Filter: blur(3px)
struct TorchGlowView: View {
    let cursorX: CGFloat
    let isActive: Bool

    var body: some View {
        if isActive {
            Canvas { context, size in
                // Updated trapezoid from new Figma SVG (106×94)
                // Scaled to fit our 67pt-tall search bar
                let svgHeight: CGFloat = 93.5
                let scale = size.height / svgHeight

                let glowWidth: CGFloat = 94 * scale
                let narrowHalfHeight: CGFloat = 12.5 * scale  // half of 25pt
                let wideHalfHeight: CGFloat = 40.75 * scale   // half of 81.5pt
                let centerY = size.height / 2

                let left = cursorX
                let right = left + glowWidth

                var path = Path()
                path.move(to: CGPoint(x: left, y: centerY - narrowHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY - wideHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY + wideHalfHeight))
                path.addLine(to: CGPoint(x: left, y: centerY + narrowHalfHeight))
                path.closeSubpath()

                // Gradient: linear-gradient(87deg, #F70 -10.87%, rgba(13,13,13,0) 87.43%)
                let gradient = Gradient(colors: [
                    Color(red: 1.0, green: 0.467, blue: 0.0),                    // #FF7700
                    Color(red: 0.051, green: 0.051, blue: 0.051).opacity(0)      // transparent
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: left - glowWidth * 0.1, y: centerY),
                        endPoint: CGPoint(x: right, y: centerY)
                    )
                )

                // Inner shadow approximation: add a subtle brighter edge on the left
                var innerEdge = Path()
                innerEdge.move(to: CGPoint(x: left, y: centerY - narrowHalfHeight))
                innerEdge.addLine(to: CGPoint(x: left + 8 * scale, y: centerY - narrowHalfHeight * 0.9))
                innerEdge.addLine(to: CGPoint(x: left + 8 * scale, y: centerY + narrowHalfHeight * 0.9))
                innerEdge.addLine(to: CGPoint(x: left, y: centerY + narrowHalfHeight))
                innerEdge.closeSubpath()

                context.fill(
                    innerEdge,
                    with: .color(Color(red: 1.0, green: 0.518, blue: 0.0).opacity(0.14))
                )
            }
            .blur(radius: 3)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.2), value: cursorX)
        }
    }
}
