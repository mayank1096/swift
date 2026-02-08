import SwiftUI

@Observable
class SearchViewModel {

    // MARK: - What the user typed

    var searchText: String = "" {
        didSet { debouncedAutocomplete() }
    }

    // MARK: - Suggestion state

    /// The currently displayed suggestion suffix (the gray text after the cursor).
    /// This changes as the carousel rotates through suggestions.
    private(set) var suggestionSuffix: String = ""

    /// The full suggested phrase for the current carousel item.
    private(set) var fullSuggestion: String = ""

    /// Controls visibility of torch glow + suggestion text.
    private(set) var showSuggestion: Bool = false

    /// All matching suffixes for the carousel (e.g. ["an excuse", "a website", "pasta", "money online"]).
    private(set) var allSuggestionSuffixes: [String] = []

    /// Which carousel item is currently showing (0, 1, 2, 3...).
    private(set) var currentSuggestionIndex: Int = 0

    // MARK: - Cursor tracking

    var cursorX: CGFloat = 0

    // MARK: - Private

    private let provider = SuggestionProvider()
    private var debounceTask: Task<Void, Never>?
    private var carouselTask: Task<Void, Never>?

    // MARK: - Debounce logic

    private func debouncedAutocomplete() {
        debounceTask?.cancel()
        carouselTask?.cancel()
        showSuggestion = false

        if searchText.isEmpty {
            suggestionSuffix = ""
            fullSuggestion = ""
            allSuggestionSuffixes = []
            return
        }

        guard searchText.contains(" ") else { return }

        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            updateSuggestion()
        }
    }

    /// Finds all matching suggestions and starts the carousel.
    private func updateSuggestion() {
        let matches = provider.multipleSuggestions(for: searchText, limit: 4)

        guard !matches.isEmpty else {
            fullSuggestion = ""
            suggestionSuffix = ""
            showSuggestion = false
            allSuggestionSuffixes = []
            return
        }

        // Build the suffix list (drop the typed part from each match)
        allSuggestionSuffixes = matches.map { String($0.dropFirst(searchText.count)) }
        currentSuggestionIndex = 0

        // Show the first suggestion
        fullSuggestion = matches[0]
        suggestionSuffix = allSuggestionSuffixes[0]
        showSuggestion = true

        // Start carousel if there are multiple suggestions
        if allSuggestionSuffixes.count > 1 {
            startCarousel()
        }
    }

    /// Cycles through suggestions every 0.8 seconds with animation.
    private func startCarousel() {
        carouselTask?.cancel()
        carouselTask = Task { @MainActor in
            // Wait 0.8s before first rotation (let the user read the first one)
            try? await Task.sleep(for: .milliseconds(800))

            while !Task.isCancelled && showSuggestion {
                // Move to next suggestion
                currentSuggestionIndex = (currentSuggestionIndex + 1) % allSuggestionSuffixes.count
                suggestionSuffix = allSuggestionSuffixes[currentSuggestionIndex]

                // Update fullSuggestion for accept-on-swipe
                let matches = provider.multipleSuggestions(for: searchText, limit: 4)
                if currentSuggestionIndex < matches.count {
                    fullSuggestion = matches[currentSuggestionIndex]
                }

                // Wait 0.8s before next rotation
                try? await Task.sleep(for: .milliseconds(800))
            }
        }
    }

    // MARK: - Accept suggestion

    func acceptSuggestion() {
        guard !fullSuggestion.isEmpty else { return }
        carouselTask?.cancel()
        searchText = fullSuggestion
        suggestionSuffix = ""
        fullSuggestion = ""
        showSuggestion = false
        allSuggestionSuffixes = []
    }
}
