import Testing
@testable import WithWhomCore

struct PersonDictionaryTests {
    @Test("given으로 찾는다")
    func givenName() {
        let dict = PersonDictionary(contacts: [Contact(given: "가람", family: "김")])
        #expect(dict.person(forToken: "가람") == "가람")
    }

    @Test("family+given으로도 찾고 대표 이름은 given이다")
    func familyPlusGiven() {
        let dict = PersonDictionary(contacts: [Contact(given: "가람", family: "김")])
        #expect(dict.person(forToken: "김가람") == "가람")
    }

    @Test("family가 비고 given이 한글 3글자면 뒤 2글자도 넣는다")
    func threeSyllableGiven() {
        let dict = PersonDictionary(contacts: [Contact(given: "김가람", family: "")])
        #expect(dict.person(forToken: "김가람") == "가람")
        #expect(dict.person(forToken: "가람") == "가람")
    }

    @Test("family가 있으면 3글자 given을 쪼개지 않는다")
    func familyPresentKeepsGiven() {
        let dict = PersonDictionary(contacts: [Contact(given: "가나다", family: "김")])
        #expect(dict.person(forToken: "가나다") == "가나다")
        #expect(dict.person(forToken: "나다") == nil)
    }

    @Test("한글 3글자가 아니면 쪼개지 않는다")
    func nonHangulGiven() {
        let dict = PersonDictionary(contacts: [Contact(given: "Anna", family: "")])
        #expect(dict.person(forToken: "Anna") == "Anna")
        #expect(dict.person(forToken: "nna") == nil)
    }

    @Test("사전에 없으면 nil이다")
    func unknown() {
        let dict = PersonDictionary(contacts: [Contact(given: "가람", family: "김")])
        #expect(dict.person(forToken: "수민") == nil)
    }

    @Test("접미사를 떼고 찾는다", arguments: ["이랑", "랑", "이가", "가", "이", "씨", "님"])
    func suffixes(suffix: String) {
        let dict = PersonDictionary(contacts: [Contact(given: "한결", family: "이")])
        #expect(dict.person(forToken: "한결" + suffix) == "한결")
    }

    @Test("긴 접미사부터 뗀다")
    func longestSuffixFirst() {
        let dict = PersonDictionary(contacts: [
            Contact(given: "한결", family: ""),
            Contact(given: "한결이", family: ""),
        ])
        #expect(dict.person(forToken: "한결이랑") == "한결")
    }

    @Test("접미사만 있는 토큰은 사람이 아니다")
    func suffixOnly() {
        let dict = PersonDictionary(contacts: [Contact(given: "가람", family: "김")])
        #expect(dict.person(forToken: "이") == nil)
        #expect(dict.person(forToken: "") == nil)
    }
}
