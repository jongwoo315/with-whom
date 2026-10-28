public struct Contact: Sendable, Equatable {
    public var given: String
    public var family: String

    public init(given: String, family: String = "") {
        self.given = given
        self.family = family
    }
}

/// 연락처에서 만든 이름 → 대표 이름 사전. 이름인지 아닌지는 이 사전에 있느냐로만 정한다.
public struct PersonDictionary: Sendable {
    // 긴 접미사부터 떼어 본다
    private static let suffixes = ["이랑", "이가", "랑", "가", "이", "씨", "님"]

    private let names: [String: String]

    public init(contacts: [Contact]) {
        var names: [String: String] = [:]
        for contact in contacts where !contact.given.isEmpty {
            let isFullName = contact.family.isEmpty && Self.isThreeHangul(contact.given)
            let representative = isFullName ? String(contact.given.suffix(2)) : contact.given
            var keys = [contact.given, contact.family + contact.given]
            if isFullName { keys.append(representative) }
            for key in keys where names[key] == nil { names[key] = representative }
        }
        self.names = names
    }

    /// 토큰 자체 또는 끝의 접미사를 뗀 꼴이 사전에 있으면 그 사람의 대표 이름을 돌려준다.
    public func person(forToken token: String) -> String? {
        if let name = names[token] { return name }
        for suffix in Self.suffixes where token.hasSuffix(suffix) {
            if let name = names[String(token.dropLast(suffix.count))] { return name }
        }
        return nil
    }

    private static func isThreeHangul(_ text: String) -> Bool {
        text.count == 3 && text.allSatisfy { char in
            guard let scalar = char.unicodeScalars.first else { return false }
            return (0xAC00...0xD7A3).contains(scalar.value) || (0x1100...0x11FF).contains(scalar.value)
        }
    }
}
