# iOS Torch Search Bar -- Implementation Plan

## Overview

An interactive search bar where typing reveals inline autocomplete suggestions with a **torch/flashlight glow effect** -- the cursor emits a warm orange light that illuminates the suggestion text ahead of it.

---

## 1. Recommended Tech Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Framework** | SwiftUI | Declarative UI with ZStack composability for the ghost-text pattern |
| **Minimum target** | iOS 17.0 | Required for `@Observable`, `#Preview` macros |
| **Glow effect** | SwiftUI `Canvas` + blur | Matches the Figma SVG trapezoid exactly without needing Metal |
| **Text input** | Invisible `TextField` + visible `Text` overlay | Full control over typed vs. suggestion text coloring |
| **Autocomplete** | Local prefix matching (100ms debounce) | Suggestion appears only after user stops typing for 100ms |
| **Architecture** | MVVM with `@Observable` | Lightweight, testable, no dependencies |
| **Font** | DM Sans (Google Fonts) | Per Figma spec |

---

## 2. Figma Design Tokens

### Screen Background
```
linear-gradient(173deg, #242424 -17.8%, #151515 60.66%)
```

### Search Bar Container
```
Width:         357px (full-width with 18px horizontal padding)
Height:        67px
Border-radius: 12px
Border:        1px solid rgba(255, 255, 255, 0.14)
Background:    #0D0D0D
Box-shadow:    0 18px 54px 0 rgba(0, 0, 0, 0.70)          (outer)
               0 0 40px 0 rgba(0, 0, 0, 0.30) inset        (inner)
```

### Torch Glow
```
Shape:    Trapezoid (narrow at cursor ~28pt, fans out right ~66pt, width ~62pt)
Fill:     linear-gradient(79deg, #FF7700 -51.56%, #0D0D0D 90.5%)
Filter:   blur(3px)
```

### Text
```
Font:           DM Sans, Regular (400)
Size:           20px
Line-height:    90% (18px)
Letter-spacing: -1px
Color (typed):  #FFFFFF
Color (suggest): #FFFFFF at 30% opacity
```

---

## 3. File Structure (Final)

```
TorchSearch/
└── Sources/
    ├── TorchSearchApp.swift           # @main entry point
    ├── ContentView.swift              # Full screen: gradient bg + title + search bar
    │
    ├── Components/
    │   ├── TorchSearchBar.swift       # ZStack: invisible TextField + visible text + glow
    │   ├── TorchGlowView.swift        # Canvas-drawn trapezoid with orange gradient + blur
    │   └── SuggestionTextView.swift   # White typed text + gray suggestion text
    │
    ├── ViewModels/
    │   └── SearchViewModel.swift      # Debounce logic, suggestion state, cursor tracking
    │
    └── Models/
        └── SuggestionProvider.swift   # Dictionary of autocomplete phrases
```

---

## 4. Two UI States

### State 1: Typing (no suggestion yet)
User is actively typing or hasn't paused for 100ms yet.
- White text visible
- Torch glow at cursor
- No suggestion suffix

### State 2: Suggestion visible (100ms after last keystroke)
User paused typing. Best match found.
- White text: what they typed ("How to make")
- Gray text: suggestion suffix (" an excuse")
- Torch glow at the boundary between the two
- Swipe right to accept suggestion

---

## 5. How to Set Up in Xcode

1. Create a new Xcode project: **iOS > App > SwiftUI**
2. Product name: `TorchSearch`, target iOS 17.0+
3. Copy all files from `TorchSearch/Sources/` into your Xcode project
4. **Add DM Sans font:**
   - Download `DMSans-Regular.ttf` from Google Fonts
   - Drag it into your Xcode project (check "Copy items if needed")
   - Add to `Info.plist` under "Fonts provided by application": `DMSans-Regular.ttf`
5. Build and run on a physical device or simulator
