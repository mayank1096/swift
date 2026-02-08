import SwiftUI

/// The "brain" of the search bar.
///
/// It keeps track of:
/// - What the user has typed (`searchText`)
/// - What we're suggesting (`suggestionSuffix`) — the gray part
/// - Where the cursor is on screen (`cursorX`) — so the torch glow knows where to sit
///
/// It also handles "debouncing": waiting 100ms after the user stops typing
/// before computing a suggestion, so we don't waste work on every single keystroke.
@Observable
class SearchViewModel {

    // MARK: - What the user typed

    /// The actual text the user has entered. Bound to the invisible TextField.
    var searchText: String = "" {
        didSet { debouncedAutocomplete() }
    }

    // MARK: - Suggestion state

    /// Just the part we're suggesting (e.g. "an excuse" if the full match is "How to make an excuse").
    /// This is the gray text shown after the cursor.
    private(set) var suggestionSuffix: String = ""

    /// The full suggested phrase (typed part + suggestion part combined).
    /// Used when the user "accepts" the suggestion.
    private(set) var fullSuggestion: String = ""

    /// Controls whether the torch glow AND the gray suggestion text are visible.
    /// Only becomes true AFTER the 100ms debounce completes and a suggestion is found.
    /// This means: while the user is actively typing, no torch and no gray text.
    private(set) var showSuggestion: Bool = false

    // MARK: - Cursor tracking

    /// The X position (in points) of where the typed text ends.
    /// The torch glow trapezoid is positioned here.
    var cursorX: CGFloat = 0

    // MARK: - Private

    /// Our dictionary of suggestions.
    private let provider = SuggestionProvider()

    /// The debounce timer task. We cancel the old one each time the user types,
    /// so only the LAST keystroke (after 100ms of silence) triggers a suggestion lookup.
    private var debounceTask: Task<Void, Never>?

    // MARK: - Debounce logic

    /// Called every time `searchText` changes.
    /// Cancels any pending suggestion lookup and starts a new 100ms timer.
    private func debouncedAutocomplete() {
        // Cancel the previous timer (user is still typing)
        debounceTask?.cancel()

        // While typing, hide torch + suggestion immediately
        showSuggestion = false

        // If the user cleared the field, immediately clear suggestions
        if searchText.isEmpty {
            suggestionSuffix = ""
            fullSuggestion = ""
            return
        }

        // Don't suggest until the user has typed at least one full word
        // (i.e. the text must contain a space, like "How ")
        guard searchText.contains(" ") else { return }

        // Start a new 500ms timer
        debounceTask = Task { @MainActor in
            // Wait 500ms after user stops typing
            try? await Task.sleep(for: .milliseconds(500))

            // If this task wasn't cancelled (user didn't type again), compute the suggestion
            guard !Task.isCancelled else { return }
            updateSuggestion()
        }
    }

    /// Looks up the best suggestion and splits it into the suffix part.
    /// Also turns on showSuggestion so the torch + gray text appear together.
    private func updateSuggestion() {
        if let match = provider.topSuggestion(for: searchText) {
            fullSuggestion = match
            // Drop the part the user already typed to get just the suggestion tail
            suggestionSuffix = String(match.dropFirst(searchText.count))
            showSuggestion = true
        } else {
            fullSuggestion = ""
            suggestionSuffix = ""
            showSuggestion = false
        }
    }

    // MARK: - Accept suggestion

    /// When the user taps to accept the suggestion, fill in the full text.
    func acceptSuggestion() {
        guard !fullSuggestion.isEmpty else { return }
        searchText = fullSuggestion
        suggestionSuffix = ""
        fullSuggestion = ""
        showSuggestion = false
    }
}
