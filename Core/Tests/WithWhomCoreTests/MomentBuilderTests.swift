import Foundation
import Testing
@testable import WithWhomCore

struct MomentBuilderTests {
    let dict = PersonDictionary(contacts: [Contact(given: "가람", family: "김")])
    let start = Date(timeIntervalSince1970: 1_780_000_000)

    func event(_ id: String, _ title: String, recurring: Bool = false) -> EventInput {
        EventInput(id: id, title: title, start: start, end: start.addingTimeInterval(3600), isRecurring: recurring)
    }

    @Test("반복 일정은 뺀다")
    func dropsRecurring() {
        let drafts = MomentBuilder.build([event("a", "가람이 - 잡채"), event("b", "보험료", recurring: true)], dictionary: dict)
        #expect(drafts.map(\.sourceId) == ["a"])
    }

    @Test("같은 id가 두 번 들어오면 하나만 남긴다")
    func dedupesById() {
        let drafts = MomentBuilder.build([event("a", "가람이 - 잡채"), event("a", "가람이 - 영화")], dictionary: dict)
        #expect(drafts.count == 1)
        #expect(drafts[0].items == ["잡채"])
    }

    @Test("review 결과는 needsReview가 true다")
    func reviewFlag() {
        let drafts = MomentBuilder.build([event("a", "가람이 - 잡채"), event("b", "헤어컷")], dictionary: dict)
        #expect(drafts[0].needsReview == false)
        #expect(drafts[0].people == ["가람"])
        #expect(drafts[1].needsReview == true)
        #expect(drafts[1].people.isEmpty)
        #expect(drafts[1].items == ["헤어컷"])
    }

    @Test("date는 지정한 시간대 기준 시작일이다")
    func dateIsStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        // 2026-06-01 23:30 KST = 14:30 UTC
        let late = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 23, minute: 30))!
        let input = EventInput(id: "a", title: "헤어컷", start: late, end: late.addingTimeInterval(1800), isRecurring: false)
        let draft = MomentBuilder.build([input], dictionary: dict, calendar: calendar)[0]
        #expect(draft.date == calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        #expect(draft.title == "헤어컷")
        #expect(draft.start == late)
        #expect(draft.end == late.addingTimeInterval(1800))
    }

    @Test("build가 만든 초안은 모두 장소가 없다")
    func draftsHaveNoPlace() {
        let drafts = MomentBuilder.build([event("a", "가람이 - 잡채"), event("b", "헤어컷")], dictionary: dict)
        #expect(drafts.count == 2)
        #expect(drafts.allSatisfy { $0.place == nil })
    }

    @Test("Place는 이름 없이 좌표만 가질 수 있다")
    func placeWithoutName() {
        let place = Place(name: nil, latitude: 37.5, longitude: 127.0)
        #expect(place.name == nil)
        #expect(place == Place(name: nil, latitude: 37.5, longitude: 127.0))
    }

    @Test("별칭을 넣으면 같은 제목이 확인 필요에서 풀린다")
    func interpretAfterAlias() {
        let before = MomentBuilder.interpret("자기 🤍 - 북엇국", dictionary: dict)
        #expect(before.needsReview && before.people.isEmpty && before.items.count == 1)
        let withAlias = PersonDictionary(contacts: [Contact(given: "가람", family: "김")], aliases: ["자기": "다솜"])
        let after = MomentBuilder.interpret("자기 🤍 - 북엇국", dictionary: withAlias)
        #expect(!after.needsReview && after.people == ["다솜"] && after.items == ["북엇국"])
    }

    @Test("별칭이 없는 낱말의 제목은 사전이 바뀌어도 그대로다")
    func interpretUnrelatedTitle() {
        let withAlias = PersonDictionary(contacts: [Contact(given: "가람", family: "김")], aliases: ["자기": "다솜"])
        #expect(MomentBuilder.interpret("헤어컷", dictionary: withAlias) == MomentBuilder.interpret("헤어컷", dictionary: dict))
    }
}
