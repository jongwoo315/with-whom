import Foundation

public enum ParseResult: Equatable, Sendable {
    case auto(people: Set<String>, items: [String])
    case review(items: [String])
}

public enum TitleParser {
    public static func parse(_ title: String, dictionary: PersonDictionary) -> ParseResult {
        let cleaned = title
            .replacingOccurrences(of: "🤍", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let left: String
        let rightItems: [String]
        if let dash = cleaned.range(of: " - ") {
            left = String(cleaned[..<dash.lowerBound])
            rightItems = cleaned[dash.upperBound...]
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } else {
            left = cleaned
            rightItems = []
        }

        var people = Set<String>()
        var items: [String] = []

        func extractItem(from tokens: [Substring]) -> String? {
            var rest: [Substring] = []
            for token in tokens {
                if let person = dictionary.person(forToken: String(token)) {
                    people.insert(person)
                } else {
                    rest.append(token)
                }
            }
            return rest.isEmpty ? nil : rest.joined(separator: " ")
        }

        if let item = extractItem(from: left.split(whereSeparator: { $0 == "," || $0.isWhitespace })) {
            items.append(item)
        }
        for raw in rightItems {
            if let item = extractItem(from: raw.split(whereSeparator: \.isWhitespace)) {
                items.append(item)
            }
        }

        if people.isEmpty {
            return .review(items: cleaned.isEmpty ? [] : [cleaned])
        }
        return .auto(people: people, items: items)
    }
}
