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

    /// Returns the single best matching suggestion (used for accept-on-swipe).
    func topSuggestion(for prefix: String) -> String? {
        guard !prefix.isEmpty else { return nil }
        let lowered = prefix.lowercased()
        return phrases.first { phrase in
            phrase.lowercased().hasPrefix(lowered)
                && phrase.lowercased() != lowered
        }
    }

    /// Returns up to `limit` matching suggestions for the carousel.
    func multipleSuggestions(for prefix: String, limit: Int = 4) -> [String] {
        guard !prefix.isEmpty else { return [] }
        let lowered = prefix.lowercased()
        return Array(
            phrases
                .filter { $0.lowercased().hasPrefix(lowered) && $0.lowercased() != lowered }
                .prefix(limit)
        )
    }
}
