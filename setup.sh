#!/bin/bash

# ============================================================
# TorchSearch Project Setup Script (v2)
#
# HOW TO USE:
# 1. Open Terminal on your Mac
# 2. Copy-paste this entire script into Terminal
# 3. Press Enter
# ============================================================

PROJECT_DIR="$HOME/Desktop/TorchSearch"

echo "Creating TorchSearch project on your Desktop..."

rm -rf "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/TorchSearch/Components"
mkdir -p "$PROJECT_DIR/TorchSearch/ViewModels"
mkdir -p "$PROJECT_DIR/TorchSearch/Models"

echo "Folders created."

# ── FILE 1: TorchSearchApp.swift ──
cat > "$PROJECT_DIR/TorchSearch/TorchSearchApp.swift" << 'SWIFT'
import SwiftUI

@main
struct TorchSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
SWIFT

# ── FILE 2: ContentView.swift ──
cat > "$PROJECT_DIR/TorchSearch/ContentView.swift" << 'SWIFT'
import SwiftUI

struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                titleText
                    .frame(width: 254)

                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 18)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

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
        .lineSpacing(34 * 0.1)
    }
}

#Preview {
    ContentView()
}
SWIFT

# ── FILE 3: TorchSearchBar.swift ──
cat > "$PROJECT_DIR/TorchSearch/Components/TorchSearchBar.swift" << 'SWIFT'
import SwiftUI

struct TorchSearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            TorchGlowView(
                cursorX: viewModel.cursorX + 20,
                isActive: viewModel.showSuggestion
            )

            SuggestionTextView(
                typedText: viewModel.searchText,
                suggestion: viewModel.showSuggestion ? viewModel.suggestionSuffix : "",
                onCursorXChange: { x in
                    viewModel.cursorX = x
                }
            )
            .padding(.leading, 20)
            .padding(.trailing, 56)

            TextField("", text: $viewModel.searchText, prompt: searchPrompt)
                .foregroundStyle(.clear)
                .tint(Color(red: 1.0, green: 0.467, blue: 0.0))
                .font(.custom("DMSans-Regular", size: 18))
                .tracking(-0.9)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.leading, 20)
                .padding(.trailing, 56)

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
                .fill(Color(red: 0.051, green: 0.051, blue: 0.051))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    private var searchPrompt: Text {
        Text("Search anything...")
            .foregroundStyle(.white.opacity(0.3))
            .font(.custom("DMSans-Regular", size: 18))
    }

    private var micIcon: some View {
        Canvas { context, size in
            let scale = size.width / 22.0

            var micBody = Path()
            let capsuleRect = CGRect(
                x: 8.25 * scale, y: 1.833 * scale,
                width: 5.5 * scale, height: 11.917 * scale
            )
            micBody.addRoundedRect(in: capsuleRect, cornerSize: CGSize(width: 2.75 * scale, height: 2.75 * scale))

            var standLine = Path()
            standLine.move(to: CGPoint(x: 11 * scale, y: 17.417 * scale))
            standLine.addLine(to: CGPoint(x: 11 * scale, y: 20.167 * scale))

            var arcPath = Path()
            arcPath.move(to: CGPoint(x: 17.416 * scale, y: 9.167 * scale))
            arcPath.addLine(to: CGPoint(x: 17.416 * scale, y: 11 * scale))
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
            let color = Color(red: 0.251, green: 0.251, blue: 0.251)

            context.stroke(micBody, with: .color(color), style: strokeStyle)
            context.stroke(standLine, with: .color(color), style: strokeStyle)
            context.stroke(arcPath, with: .color(color), style: strokeStyle)
        }
    }
}
SWIFT

# ── FILE 4: SuggestionTextView.swift ──
cat > "$PROJECT_DIR/TorchSearch/Components/SuggestionTextView.swift" << 'SWIFT'
import SwiftUI

struct SuggestionTextView: View {
    let typedText: String
    let suggestion: String
    var onCursorXChange: ((CGFloat) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
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

            if !suggestion.isEmpty {
                Text(suggestion)
                    .foregroundStyle(.white.opacity(0.3))
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
            }
        }
        .font(.custom("DMSans-Regular", size: 18))
        .tracking(-0.9)
        .lineLimit(1)
    }
}
SWIFT

# ── FILE 5: TorchGlowView.swift ──
cat > "$PROJECT_DIR/TorchSearch/Components/TorchGlowView.swift" << 'SWIFT'
import SwiftUI

struct TorchGlowView: View {
    let cursorX: CGFloat
    let isActive: Bool

    var body: some View {
        if isActive {
            Canvas { context, size in
                let svgHeight: CGFloat = 93.5
                let scale = size.height / svgHeight

                let glowWidth: CGFloat = 94 * scale
                let narrowHalfHeight: CGFloat = 12.5 * scale
                let wideHalfHeight: CGFloat = 40.75 * scale
                let centerY = size.height / 2

                let left = cursorX
                let right = left + glowWidth

                var path = Path()
                path.move(to: CGPoint(x: left, y: centerY - narrowHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY - wideHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY + wideHalfHeight))
                path.addLine(to: CGPoint(x: left, y: centerY + narrowHalfHeight))
                path.closeSubpath()

                let gradient = Gradient(colors: [
                    Color(red: 1.0, green: 0.467, blue: 0.0),
                    Color(red: 0.051, green: 0.051, blue: 0.051).opacity(0)
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: left - glowWidth * 0.1, y: centerY),
                        endPoint: CGPoint(x: right, y: centerY)
                    )
                )

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
SWIFT

# ── FILE 6: SearchViewModel.swift ──
cat > "$PROJECT_DIR/TorchSearch/ViewModels/SearchViewModel.swift" << 'SWIFT'
import SwiftUI

@Observable
class SearchViewModel {

    var searchText: String = "" {
        didSet { debouncedAutocomplete() }
    }

    private(set) var suggestionSuffix: String = ""
    private(set) var fullSuggestion: String = ""
    private(set) var showSuggestion: Bool = false
    var cursorX: CGFloat = 0

    private let provider = SuggestionProvider()
    private var debounceTask: Task<Void, Never>?

    private func debouncedAutocomplete() {
        debounceTask?.cancel()
        showSuggestion = false

        if searchText.isEmpty {
            suggestionSuffix = ""
            fullSuggestion = ""
            return
        }

        guard searchText.contains(" ") else { return }

        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            updateSuggestion()
        }
    }

    private func updateSuggestion() {
        if let match = provider.topSuggestion(for: searchText) {
            fullSuggestion = match
            suggestionSuffix = String(match.dropFirst(searchText.count))
            showSuggestion = true
        } else {
            fullSuggestion = ""
            suggestionSuffix = ""
            showSuggestion = false
        }
    }

    func acceptSuggestion() {
        guard !fullSuggestion.isEmpty else { return }
        searchText = fullSuggestion
        suggestionSuffix = ""
        fullSuggestion = ""
        showSuggestion = false
    }
}
SWIFT

# ── FILE 7: SuggestionProvider.swift ──
cat > "$PROJECT_DIR/TorchSearch/Models/SuggestionProvider.swift" << 'SWIFT'
import Foundation

struct SuggestionProvider {
    private let phrases: [String] = [
        "How to make an excuse",
        "How to make a website",
        "How to make pasta from scratch",
        "How to make money online",
        "How to make a resume",
        "How to make friends",
        "How to make pancakes",
        "How to make a budget",
        "How to make coffee",
        "How to make slime",
        "How to learn Swift programming",
        "How to learn design",
        "How to start a business",
        "How to invest in stocks",
        "Best restaurants near me",
        "Best laptops 2026",
        "Best movies to watch",
        "What is artificial intelligence",
        "What is the meaning of life",
        "Why is the sky blue",
    ]

    func topSuggestion(for prefix: String) -> String? {
        guard !prefix.isEmpty else { return nil }
        let lowered = prefix.lowercased()
        return phrases.first { phrase in
            phrase.lowercased().hasPrefix(lowered)
                && phrase.lowercased() != lowered
        }
    }
}
SWIFT

# ── FILE 8: Info.plist ──
cat > "$PROJECT_DIR/TorchSearch/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UIAppFonts</key>
    <array>
        <string>DMSans-Regular.ttf</string>
        <string>DMSans-Medium.ttf</string>
        <string>PlayfairDisplay-Italic.ttf</string>
    </array>
</dict>
</plist>
PLIST

echo ""
echo "All 8 files created!"
echo ""
echo "Project location: $PROJECT_DIR"
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Replace the files in your existing Xcode project with these"
echo ""
echo "  2. Add these fonts to your project (download from Google Fonts):"
echo "     - DMSans-Regular.ttf"
echo "     - DMSans-Medium.ttf"
echo "     - PlayfairDisplay-Italic.ttf"
echo ""
echo "  3. Add the background image to Assets.xcassets as 'Background'"
echo ""
echo "  4. Press Cmd+R to run!"

open "$PROJECT_DIR"
