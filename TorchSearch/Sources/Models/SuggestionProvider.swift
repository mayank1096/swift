import Foundation

/// A simple local dictionary of search phrases.
/// When the user types something, we find the first phrase that starts with what they typed
/// and show the rest of it as a gray "suggestion".
struct SuggestionProvider {

    /// Our list of canned suggestions. You can swap this out for an API call later.
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

    /// Given what the user has typed so far, return the best matching full phrase.
    /// Returns nil if nothing matches.
    func topSuggestion(for prefix: String) -> String? {
        guard !prefix.isEmpty else { return nil }

        let lowered = prefix.lowercased()
        return phrases.first { phrase in
            // Must start with what the user typed AND not be an exact match
            // (no point suggesting "How to make" if they already typed "How to make")
            phrase.lowercased().hasPrefix(lowered)
                && phrase.lowercased() != lowered
        }
    }
}
