import Foundation

public enum ParseResult: Equatable, Sendable {
    case auto(people: Set<String>, items: [String])
    case review(items: [String])
}

public enum TitleParser {
    /// 제목을 해석 규칙대로 나눈 조각. 왼쪽은 쉼표·공백으로, 오른쪽은 쉼표로 나눈 항목을 공백으로 다시 나눈다.
    private static func split(_ title: String) -> (left: [Substring], right: [[Substring]], cleaned: String) {
        let cleaned = title
            .replacingOccurrences(of: "🤍", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let dash = cleaned.range(of: " - ") else {
            return (cleaned.split(whereSeparator: { $0 == "," || $0.isWhitespace }), [], cleaned)
        }
        let left = String(cleaned[..<dash.lowerBound])
        let right = cleaned[dash.upperBound...]
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).split(whereSeparator: \.isWhitespace) }
        return (left.split(whereSeparator: { $0 == "," || $0.isWhitespace }), right, cleaned)
    }

    /// `parse`와 같은 규칙으로 나눈 낱말 목록. 순서를 지키고 중복은 뺀다.
    /// 글자나 숫자가 하나도 없는 조각(`영화 - 저녁`의 `-`)은 별칭 후보가 될 수 없어 뺀다.
    public static func tokens(_ title: String) -> [String] {
        let parts = split(title)
        var seen = Set<String>()
        return (parts.left + parts.right.flatMap { $0 }).map(String.init)
            .filter { $0.contains { $0.isLetter || $0.isNumber } }
            .filter { seen.insert($0).inserted }
    }

    public static func parse(_ title: String, dictionary: PersonDictionary) -> ParseResult {
        let parts = split(title)

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

        if let item = extractItem(from: parts.left) { items.append(item) }
        for raw in parts.right {
            if let item = extractItem(from: raw) { items.append(item) }
        }

        if people.isEmpty {
            return .review(items: parts.cleaned.isEmpty ? [] : [parts.cleaned])
        }
        return .auto(people: people, items: items)
    }
}
