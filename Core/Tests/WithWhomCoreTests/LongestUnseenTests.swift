import Foundation
import Testing
@testable import WithWhomCore

struct LongestUnseenTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    func at(_ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    func pick(_ lastSeen: [(name: String, last: Date)]) -> (name: String, days: Int)? {
        LongestUnseen.pick(lastSeen, now: at(10, 30, 9), calendar: Self.calendar)
    }

    @Test("빈 목록이면 nil")
    func empty() {
        #expect(pick([]) == nil)
    }

    @Test("날 수가 가장 큰 사람을 고른다")
    func longest() {
        let result = pick([("가람", at(10, 20, 12)), ("나래", at(10, 1, 18))])
        #expect(result?.name == "나래")
        #expect(result?.days == 29)
    }

    @Test("24시간이 안 지났어도 날짜가 다르면 하루다")
    func calendarDays() {
        let result = pick([("가람", at(10, 29, 23, 30))])
        #expect(result?.name == "가람")
        #expect(result?.days == 1)
    }

    @Test("앞으로 잡힌 약속은 만난 것이 아니라서 무시한다")
    func futureIgnored() {
        #expect(pick([("가람", at(11, 5, 12))]) == nil)
    }

    @Test("미래 항목만 빠지고 나머지는 남는다")
    func futureIgnoredOthersStay() {
        let result = pick([("가람", at(11, 5, 12)), ("나래", at(10, 28, 12))])
        #expect(result?.name == "나래")
        #expect(result?.days == 2)
    }

    @Test("날 수가 같으면 이름 오름차순 첫 번째")
    func tieBreaksByName() {
        let result = pick([("다솜", at(10, 1, 9)), ("가람", at(10, 1, 9))])
        #expect(result?.name == "가람")
        #expect(result?.days == 29)
    }

    @Test("같은 날이면 시각이 달라도 날 수가 같아 이름 순으로 고른다")
    func tieIgnoresTimeOfDay() {
        let result = pick([("다솜", at(10, 1, 8)), ("가람", at(10, 1, 23))])
        #expect(result?.name == "가람")
        #expect(result?.days == 29)
    }

    @Test("가장 오래된 사람이 목록 가운데 있어도 고른다")
    func oldestInMiddle() {
        let result = pick([("나래", at(10, 20, 9)), ("가람", at(10, 1, 9)), ("다솜", at(10, 10, 9))])
        #expect(result?.name == "가람")
        #expect(result?.days == 29)
    }
}
