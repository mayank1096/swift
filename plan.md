# iOS Torch Search Bar -- Implementation Plan

## Overview

An interactive search bar where typing reveals inline autocomplete suggestions with a **torch/flashlight glow effect** -- the cursor emits a warm orange light that illuminates the suggestion text ahead of it.

![Reference UI](reference: typed text in white, suggestion in gray, orange glow at cursor)

---

## 1. Recommended Tech Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Framework** | SwiftUI | Native declarative UI, first-class Metal shader support via `.colorEffect()` / `.layerEffect()` |
| **Minimum target** | iOS 17.0 | Required for `ShaderLibrary`, `.visualEffect`, and `#Preview` macros |
| **Glow effect** | Metal shader (`.metal` file) | Per-pixel Gaussian falloff with directional beam -- impossible to achieve with pure SwiftUI gradients |
| **Text input** | Invisible `TextField` + visible `Text` overlay (ZStack ghost-text pattern) | Full visual control over typed vs. suggested text coloring |
| **Autocomplete engine** | Local prefix matching (expandable to API-backed) | Start simple, swap in network calls later |
| **Architecture** | MVVM with `@Observable` (iOS 17) | Lightweight, testable, no third-party dependencies |
| **Animation** | SwiftUI `withAnimation` + Metal shader uniforms | Smooth cursor-tracking glow with ambient pulsation |
| **Package manager** | Swift Package Manager (SPM) | No external dependencies needed for v1 |

### Why not UIKit?

UIKit's `UITextField` does not allow independent coloring of typed vs. autocomplete text inline. The `selectedTextRange` trick highlights suggestions with the system selection color -- you cannot make it gray or apply a glow. SwiftUI's composability (ZStack + Metal shaders) makes this effect achievable with clean code.

---

## 2. File Structure

```
TorchSearch/
├── TorchSearch.xcodeproj
├── TorchSearch/
│   ├── TorchSearchApp.swift              # App entry point
│   ├── ContentView.swift                 # Main screen hosting the search bar
│   │
│   ├── Components/
│   │   ├── TorchSearchBar.swift          # The search bar component (ZStack pattern)
│   │   ├── GlowingCursor.swift           # Cursor position tracker + glow overlay
│   │   └── SuggestionTextView.swift      # Typed text + ghost suggestion text renderer
│   │
│   ├── Shaders/
│   │   └── TorchGlow.metal               # Metal shader for directional torch effect
│   │
│   ├── ViewModels/
│   │   └── SearchViewModel.swift         # Autocomplete logic, debouncing, state
│   │
│   ├── Models/
│   │   └── SuggestionProvider.swift      # Data source for autocomplete suggestions
│   │
│   ├── Extensions/
│   │   └── View+CursorPosition.swift     # Helper to measure text width for cursor X
│   │
│   ├── Resources/
│   │   └── Assets.xcassets               # Colors, icons
│   │
│   └── Preview Content/
│       └── PreviewSuggestionProvider.swift
│
└── TorchSearchTests/
    ├── SearchViewModelTests.swift
    └── SuggestionProviderTests.swift
```

---

## 3. Step-by-Step Implementation Plan

### Phase 1: Project Scaffolding

**Step 1.1 -- Create Xcode project**
- New SwiftUI App, target iOS 17.0+
- Product name: `TorchSearch`
- Create the folder structure above

**Step 1.2 -- Define the data model**
- Create `SuggestionProvider.swift` with a static list of common search phrases
- Interface: `func suggestions(for prefix: String) -> [String]`
- Return matches sorted by relevance (exact prefix match first)

```swift
// SuggestionProvider.swift
struct SuggestionProvider {
    private let phrases: [String] = [
        "How to make an excuse",
        "How to make a website",
        "How to make pasta",
        "How to make money online",
        "How to make a resume",
        // ...
    ]

    func topSuggestion(for prefix: String) -> String? {
        guard !prefix.isEmpty else { return nil }
        return phrases.first {
            $0.lowercased().hasPrefix(prefix.lowercased()) && $0.lowercased() != prefix.lowercased()
        }
    }
}
```

---

### Phase 2: Core Search Bar (Ghost-Text Pattern)

**Step 2.1 -- Build the invisible TextField + visible Text overlay**

The key technique: stack an invisible `TextField` on top of visible `Text` views.

```swift
// TorchSearchBar.swift
struct TorchSearchBar: View {
    @Bindable var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Layer 1: Visual text (what the user sees)
            SuggestionTextView(
                typedText: viewModel.searchText,
                suggestion: viewModel.suggestionSuffix
            )

            // Layer 2: Invisible functional TextField
            TextField("", text: $viewModel.searchText)
                .foregroundStyle(.clear)
                .tint(.orange)          // cursor color
                .font(.system(size: 24, weight: .regular))
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.15))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture { isFocused = true }
    }
}
```

**Step 2.2 -- Build the SuggestionTextView**

```swift
// SuggestionTextView.swift
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
                            .onChange(of: typedText) { _, _ in
                                onCursorXChange?(geo.size.width)
                            }
                            .onAppear {
                                onCursorXChange?(geo.size.width)
                            }
                    }
                )

            Text(suggestion)
                .foregroundStyle(.white.opacity(0.3))
        }
        .font(.system(size: 24, weight: .regular))
        .lineLimit(1)
    }
}
```

**Step 2.3 -- Build the SearchViewModel**

```swift
// SearchViewModel.swift
@Observable
class SearchViewModel {
    var searchText: String = "" {
        didSet { debouncedAutocomplete() }
    }

    private(set) var suggestionSuffix: String = ""
    private(set) var fullSuggestion: String = ""

    private let provider = SuggestionProvider()
    private var debounceTask: Task<Void, Never>?

    var cursorX: CGFloat = 0

    private func debouncedAutocomplete() {
        debounceTask?.cancel()
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
        } else {
            fullSuggestion = ""
            suggestionSuffix = ""
        }
    }

    func acceptSuggestion() {
        guard !fullSuggestion.isEmpty else { return }
        searchText = fullSuggestion
        suggestionSuffix = ""
    }
}
```

---

### Phase 3: Metal Torch Glow Shader

**Step 3.1 -- Write the Metal shader**

```metal
// TorchGlow.metal
#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]]
half4 torchGlow(
    float2 position,
    half4 color,
    float2 cursorOrigin,
    float2 viewSize,
    float intensity,
    float radius
) {
    float2 delta = position - cursorOrigin;

    // Directional: only illuminate forward (right of cursor)
    float forwardFactor = smoothstep(-5.0, 30.0, delta.x);

    // Vertical beam falloff (concentrated beam, not a sphere)
    float verticalFalloff = exp(-delta.y * delta.y / (radius * radius * 4.0));

    // Horizontal distance falloff
    float horizDist = max(delta.x, 0.0);
    float horizFalloff = exp(-horizDist / (radius * 2.0));

    // Combined glow
    float glow = forwardFactor * verticalFalloff * horizFalloff * intensity;

    // Warm amber torch color
    half4 torchColor = half4(1.0h, 0.55h, 0.1h, 0.0h);

    // Additive blend: brighten existing content
    half4 result = color;
    result.rgb += torchColor.rgb * half(glow) * color.a;

    return result;
}
```

**Step 3.2 -- Apply the shader to the text layer**

```swift
// In TorchSearchBar.swift, wrap the SuggestionTextView:
SuggestionTextView(
    typedText: viewModel.searchText,
    suggestion: viewModel.suggestionSuffix,
    onCursorXChange: { x in viewModel.cursorX = x }
)
.visualEffect { content, proxy in
    content.layerEffect(
        ShaderLibrary.torchGlow(
            .float2(viewModel.cursorX, proxy.size.height / 2),
            .float2(proxy.size),
            .float(1.2),    // intensity
            .float(50.0)    // radius
        ),
        maxSampleOffset: .zero
    )
}
```

**Step 3.3 -- Add subtle glow animation**

Add a breathing/pulsating effect to the glow intensity:

```swift
@State private var glowPulse: CGFloat = 1.0

// In body:
.onAppear {
    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
        glowPulse = 1.3
    }
}

// Pass glowPulse as the intensity uniform to the shader
```

---

### Phase 4: Background & Chrome

**Step 4.1 -- Dark background with depth**

```swift
// ContentView.swift
struct ContentView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Spacer()
                TorchSearchBar(viewModel: viewModel)
                    .padding(.horizontal, 24)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
```

**Step 4.2 -- Search bar border with subtle glow**

Add an outer glow to the search bar container that responds to focus:

```swift
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(
            isFocused
                ? Color.orange.opacity(0.3)
                : Color.white.opacity(0.08),
            lineWidth: 1
        )
        .blur(radius: isFocused ? 4 : 0)
)
```

---

### Phase 5: Interaction Polish

**Step 5.1 -- Tab-to-accept gesture**
- Detect hardware keyboard Tab key to accept the full suggestion
- On software keyboard: add a subtle "tap to complete" affordance or right-swipe gesture on the text field

**Step 5.2 -- Keyboard appearance**
- Use `.keyboardType(.webSearch)` or `.default`
- Set `.submitLabel(.search)` for the return key

**Step 5.3 -- Haptic feedback**
- Light haptic on suggestion appearance
- Medium haptic on suggestion acceptance

```swift
let haptic = UIImpactFeedbackGenerator(style: .light)
haptic.impactOccurred()
```

**Step 5.4 -- Transition animations**
- Animate search bar expansion on focus
- Fade-in for suggestion text appearance

---

### Phase 6: Testing & Refinement

**Step 6.1 -- Unit tests**
- `SearchViewModel`: verify debouncing, suggestion matching, accept behavior
- `SuggestionProvider`: verify prefix matching, case insensitivity, empty input

**Step 6.2 -- Visual testing**
- Test on multiple device sizes (iPhone SE, 15 Pro, 16 Pro Max)
- Verify glow effect looks correct in both light and dark environments
- Test with long suggestion text (truncation behavior)
- Test with RTL text

**Step 6.3 -- Performance**
- Profile Metal shader on older devices (iPhone 12 minimum)
- Ensure debounce prevents excessive recomputation
- Verify smooth 60fps during typing

---

## 4. Key Technical Decisions

### Why ZStack ghost-text over native `searchSuggestions`?
Apple's `.searchSuggestions` renders a **dropdown list**, not inline text. The torch effect requires suggestion text to appear **inside the text field** next to the cursor -- only the ghost-text pattern supports this.

### Why Metal over pure SwiftUI gradients?
A `RadialGradient` cannot produce a **directional** beam that only illuminates forward from the cursor. The Metal shader computes per-pixel with directional smoothstep, giving the authentic torch look from the design reference.

### Why `@Observable` over `ObservableObject`?
`@Observable` (iOS 17 Observation framework) provides finer-grained change tracking -- only views that read specific properties re-render when those properties change. Since cursor position updates ~30 times/second during typing, this avoids unnecessary redraws of unrelated UI.

---

## 5. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Metal shader not rendering on Simulator | Blocks development | Test on physical device early; use `#if targetEnvironment(simulator)` fallback with RadialGradient |
| Cursor position calculation drifts with variable-width fonts | Glow misaligned | Use monospaced font or measure with `CTLineGetTypographicBounds` |
| Invisible TextField cursor visible behind glow | Visual artifact | Set `.tint(.clear)` when glow is active, or match tint to glow color |
| Suggestion flicker during fast typing | Poor UX | Debounce at 100-150ms; keep previous suggestion visible during debounce |

---

## 6. Future Enhancements (Out of Scope for v1)

- Network-backed suggestions (search API integration)
- Suggestion carousel (swipe up/down through multiple suggestions)
- Voice input with animated glow expansion
- Particle effects trailing the cursor glow
