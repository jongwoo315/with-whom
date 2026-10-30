public struct Contact: Sendable, Equatable {
    public var given: String
    public var family: String

    public init(given: String, family: String = "") {
        self.given = given
        self.family = family
    }
}

/// 연락처와 별칭에서 만든 이름 → 대표 이름 사전. 이름인지 아닌지는 이 사전에 있느냐로만 정한다.
public struct PersonDictionary: Sendable {
    // 긴 접미사부터 떼어 본다
    private static let suffixes = ["이랑", "이가", "랑", "가", "이", "씨", "님"]

    private let names: [String: String]

    /// `aliases`는 낱말 → 사람 이름이다. 같은 키가 연락처에도 있으면 별칭이 우선한다.
    public init(contacts: [Contact], aliases: [String: String] = [:]) {
        var names: [String: String] = [:]
        for contact in contacts where !contact.given.isEmpty {
            let isFullName = contact.family.isEmpty && Self.isThreeHangul(contact.given)
            let representative = isFullName ? String(contact.given.suffix(2)) : contact.given
            var keys = [contact.given, contact.family + contact.given]
            if isFullName { keys.append(representative) }
            for key in keys where names[key] == nil { names[key] = representative }
        }
        for (token, name) in aliases where !token.isEmpty && !name.isEmpty { names[token] = name }
        self.names = names
    }

    /// 끝의 접미사를 하나 뗀 꼴. 떼고 남는 글자가 2글자보다 적으면 그 접미사는 건너뛰고 다음 접미사를 본다.
    /// 한 글자만 남기면 `아이`→`아`가 돼, 별칭 `아`가 `아가`·`아님` 같은 다른 낱말까지 잡는다.
    public static func baseForm(_ token: String) -> String {
        for suffix in suffixes where token.hasSuffix(suffix) && token.count - suffix.count >= 2 {
            return String(token.dropLast(suffix.count))
        }
        return token
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
