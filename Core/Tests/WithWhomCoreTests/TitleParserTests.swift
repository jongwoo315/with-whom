import Testing
@testable import WithWhomCore

struct TitleParserTests {
    let dict = PersonDictionary(contacts: [
        Contact(given: "가람", family: "김"),
        Contact(given: "나래", family: "박"),
        Contact(given: "마루", family: "최"),
        Contact(given: "다솜", family: "정"),
    ])

    @Test("🤍를 지우고 앞뒤 공백을 지운다")
    func heartAndTrim() {
        #expect(TitleParser.parse("  가람이 🤍 - 잡채  ", dictionary: dict)
            == .auto(people: ["가람"], items: ["잡채"]))
    }

    @Test("처음 ' - ' 앞은 왼쪽, 뒤는 ,로 나눈 항목이다")
    func splitAtDash() {
        #expect(TitleParser.parse("가람이 - 잡채, 영화 보기", dictionary: dict)
            == .auto(people: ["가람"], items: ["잡채", "영화 보기"]))
    }

    @Test("' - '가 두 번 나와도 처음 것에서만 나눈다")
    func firstDashOnly() {
        #expect(TitleParser.parse("가람이 - 잡채 - 영화", dictionary: dict)
            == .auto(people: ["가람"], items: ["잡채 - 영화"]))
    }

    @Test("' - '가 없으면 제목 전체가 왼쪽이다")
    func noDash() {
        #expect(TitleParser.parse("나래 이태원", dictionary: dict)
            == .auto(people: ["나래"], items: ["이태원"]))
    }

    @Test("왼쪽 사람 아닌 토큰은 공백으로 이어 맨 앞 항목 하나가 된다")
    func leftNonPersonTokens() {
        #expect(TitleParser.parse("휴가 - 가람이랑 학교 은행나무", dictionary: dict)
            == .auto(people: ["가람"], items: ["휴가", "학교 은행나무"]))
        #expect(TitleParser.parse("가람이 사촌동생 결혼식", dictionary: dict)
            == .auto(people: ["가람"], items: ["사촌동생 결혼식"]))
    }

    @Test("왼쪽은 쉼표로도 나눈다")
    func leftComma() {
        #expect(TitleParser.parse("마루, 다솜", dictionary: dict)
            == .auto(people: ["마루", "다솜"], items: []))
    }

    @Test("오른쪽 항목에서 사람 토큰을 빼고 남은 토큰을 잇는다")
    func rightPeopleRemoved() {
        #expect(TitleParser.parse("가람이 - 나래 후 망원, 기절", dictionary: dict)
            == .auto(people: ["가람", "나래"], items: ["후 망원", "기절"]))
    }

    @Test("오른쪽 항목이 사람뿐이면 버린다")
    func rightOnlyPeopleDropped() {
        #expect(TitleParser.parse("가람이 - 나래, 잡채", dictionary: dict)
            == .auto(people: ["가람", "나래"], items: ["잡채"]))
    }

    @Test("빈 항목은 버린다")
    func emptyItems() {
        #expect(TitleParser.parse("가람이 - 잡채,, ,영화", dictionary: dict)
            == .auto(people: ["가람"], items: ["잡채", "영화"]))
    }

    @Test("사전에 없는 이름은 추측하지 않는다")
    func unknownNameIsNotPerson() {
        #expect(TitleParser.parse("수민이 점심", dictionary: dict)
            == .review(items: ["수민이 점심"]))
    }

    @Test("사람이 없으면 review이고 항목은 제목 전체 하나다")
    func noPersonReview() {
        #expect(TitleParser.parse("개발팀 회식", dictionary: dict)
            == .review(items: ["개발팀 회식"]))
        #expect(TitleParser.parse("헤어컷 🤍", dictionary: dict)
            == .review(items: ["헤어컷"]))
    }

    @Test("사람이 없으면 ' - '가 있어도 항목은 제목 전체 하나다")
    func noPersonReviewWithDash() {
        #expect(TitleParser.parse("개발팀 - 회식, 점심", dictionary: dict)
            == .review(items: ["개발팀 - 회식, 점심"]))
    }

    @Test("왼쪽에 사람이 없고 오른쪽에만 있어도 사람은 있다")
    func personOnlyOnRight() {
        #expect(TitleParser.parse("점심 - 가람이랑 잡채", dictionary: dict)
            == .auto(people: ["가람"], items: ["점심", "잡채"]))
    }

    @Test("빈 제목은 항목 없는 review다")
    func emptyTitle() {
        #expect(TitleParser.parse("  🤍 ", dictionary: dict) == .review(items: []))
    }
}
