#!/bin/bash

# ============================================================
# TorchSearch Project Setup Script
#
# This script creates the ENTIRE Xcode project structure
# and writes all the code files for you automatically.
#
# HOW TO USE:
# 1. Open Terminal on your Mac (search "Terminal" in Spotlight)
# 2. Copy-paste this entire script into Terminal
# 3. Press Enter
# 4. Open the generated .xcodeproj file in Xcode
# ============================================================

# Create project on your Desktop
PROJECT_DIR="$HOME/Desktop/TorchSearch"

echo "🔨 Creating TorchSearch project on your Desktop..."

# Clean up if it already exists
rm -rf "$PROJECT_DIR"

# Create folder structure
mkdir -p "$PROJECT_DIR/TorchSearch/Components"
mkdir -p "$PROJECT_DIR/TorchSearch/ViewModels"
mkdir -p "$PROJECT_DIR/TorchSearch/Models"
mkdir -p "$PROJECT_DIR/TorchSearch/Resources"

echo "📁 Folders created."

# ──────────────────────────────────────────────
# FILE 1: TorchSearchApp.swift (entry point)
# ──────────────────────────────────────────────
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

# ──────────────────────────────────────────────
# FILE 2: ContentView.swift (main screen)
# ──────────────────────────────────────────────
cat > "$PROJECT_DIR/TorchSearch/ContentView.swift" << 'SWIFT'
import SwiftUI

struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            // Full-screen gradient background
            // Figma: linear-gradient(173deg, #242424 -17.8%, #151515 60.66%)
            LinearGradient(
                colors: [
                    Color(red: 0.141, green: 0.141, blue: 0.141), // #242424
                    Color(red: 0.082, green: 0.082, blue: 0.082), // #151515
                ],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.6)
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Title
                Text("Search anything\non the web")
                    .font(.custom("DMSans-Regular", size: 32))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Search bar
                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 18)

                Spacer()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
SWIFT

# ──────────────────────────────────────────────
# FILE 3: TorchSearchBar.swift
# ──────────────────────────────────────────────
cat > "$PROJECT_DIR/TorchSearch/Components/TorchSearchBar.swift" << 'SWIFT'
import SwiftUI

struct TorchSearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {

            // Layer 1: The torch glow (behind everything)
            // Only shows AFTER 100ms debounce + suggestion found
            // cursorX + 20 accounts for the 20pt left padding on the text
            TorchGlowView(
                cursorX: viewModel.cursorX + 20,
                isActive: viewModel.showSuggestion
            )

            // Layer 2: The visible text (what the user actually sees)
            // Gray suggestion only appears when showSuggestion is true
            SuggestionTextView(
                typedText: viewModel.searchText,
                suggestion: viewModel.showSuggestion ? viewModel.suggestionSuffix : "",
                onCursorXChange: { x in
                    viewModel.cursorX = x
                }
            )
            .padding(.leading, 20)

            // Layer 3: The invisible TextField (handles actual typing)
            TextField("", text: $viewModel.searchText, prompt: searchPrompt)
                .foregroundStyle(.clear)
                .tint(Color(red: 1.0, green: 0.467, blue: 0.0)) // #FF7700 cursor
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.051, green: 0.051, blue: 0.051)) // #0D0D0D
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.70), radius: 27, x: 0, y: 18)
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
            .font(.custom("DMSans-Regular", size: 20))
    }
}
SWIFT

# ──────────────────────────────────────────────
# FILE 4: SuggestionTextView.swift
# ──────────────────────────────────────────────
cat > "$PROJECT_DIR/TorchSearch/Components/SuggestionTextView.swift" << 'SWIFT'
import SwiftUI

struct SuggestionTextView: View {
    let typedText: String
    let suggestion: String
    var onCursorXChange: ((CGFloat) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Bright white text the user typed
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

            // Faded suggestion text
            if !suggestion.isEmpty {
                Text(suggestion)
                    .foregroundStyle(.white.opacity(0.3))
                    .transition(.opacity.animation(.easeIn(duration: 0.15)))
            }
        }
        .font(.custom("DMSans-Regular", size: 20))
        .tracking(-1)
        .lineLimit(1)
    }
}
SWIFT

# ──────────────────────────────────────────────
# FILE 5: TorchGlowView.swift
# ──────────────────────────────────────────────
cat > "$PROJECT_DIR/TorchSearch/Components/TorchGlowView.swift" << 'SWIFT'
import SwiftUI

struct TorchGlowView: View {
    let cursorX: CGFloat
    let isActive: Bool

    var body: some View {
        if isActive {
            Canvas { context, size in
                // Trapezoid shape from Figma SVG:
                // Narrow at cursor (~28pt tall), fans out right (~66pt tall)
                let glowWidth: CGFloat = 70
                let narrowHalfHeight: CGFloat = 14
                let wideHalfHeight: CGFloat = 33
                let centerY = size.height / 2

                let left = cursorX
                let right = left + glowWidth

                var path = Path()
                path.move(to: CGPoint(x: left, y: centerY - narrowHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY - wideHalfHeight))
                path.addLine(to: CGPoint(x: right, y: centerY + wideHalfHeight))
                path.addLine(to: CGPoint(x: left, y: centerY + narrowHalfHeight))
                path.closeSubpath()

                // Figma: linear-gradient(79deg, #F70 -51.56%, #0D0D0D 90.5%)
                let gradient = Gradient(colors: [
                    Color(red: 1.0, green: 0.467, blue: 0.0),       // #FF7700
                    Color(red: 0.051, green: 0.051, blue: 0.051).opacity(0)
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
            .blur(radius: 3) // Figma: filter: blur(3px)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.2), value: cursorX)
        }
    }
}
SWIFT

# ──────────────────────────────────────────────
# FILE 6: SearchViewModel.swift
# ──────────────────────────────────────────────
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

        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
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

# ──────────────────────────────────────────────
# FILE 7: SuggestionProvider.swift
# ──────────────────────────────────────────────
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

# ──────────────────────────────────────────────
# FILE 8: Info.plist (for the DM Sans font)
# ──────────────────────────────────────────────
cat > "$PROJECT_DIR/TorchSearch/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UIAppFonts</key>
    <array>
        <string>DMSans-Regular.ttf</string>
    </array>
</dict>
</plist>
PLIST

echo ""
echo "✅ All 8 files created!"
echo ""
echo "📍 Project location: $PROJECT_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Open Xcode → File → New → Project"
echo "     → iOS → App → SwiftUI → name it 'TorchSearch'"
echo "     → save it ANYWHERE (we'll replace its files)"
echo ""
echo "  2. In Xcode's left sidebar, RIGHT-CLICK the"
echo "     'TorchSearch' folder → 'Add Files to TorchSearch'"
echo ""
echo "  3. Navigate to: ~/Desktop/TorchSearch/TorchSearch/"
echo "     Select ALL files and folders → click Add"
echo "     Check 'Copy items if needed' ✅"
echo ""
echo "  4. DELETE the old ContentView.swift and"
echo "     TorchSearchApp.swift that Xcode auto-created"
echo "     (they'll be duplicates now)"
echo ""
echo "  5. Download DMSans-Regular.ttf from Google Fonts"
echo "     and drag it into the Xcode project"
echo ""
echo "  6. Set Minimum Deployment to iOS 17.0"
echo ""
echo "  7. Press ▶ (Cmd+R) to run!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Open the folder in Finder so you can see it
open "$PROJECT_DIR"
