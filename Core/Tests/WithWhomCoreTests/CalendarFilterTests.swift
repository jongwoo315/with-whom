import Foundation
import Testing
@testable import WithWhomCore

struct CalendarFilterTests {
    func cal(_ title: String, _ source: String, _ kind: CalendarInfo.Kind) -> CalendarInfo {
        CalendarInfo(id: title, title: title, sourceTitle: source, kind: kind)
    }

    @Test("기본값은 공휴일·생일 캘린더만 뺀다")
    func defaultExcluded() {
        let samples: [(CalendarInfo, excluded: Bool)] = [
            (cal("대한민국 공휴일", "기타", .subscription), true),
            (cal("대한민국의 휴일", "jw@gmail.com", .calDAV), true),
            (cal("Holidays in South Korea", "iCloud", .calDAV), true),
            (cal("생일", "기타", .birthday), true),
            (cal("jw@gmail.com", "jw@gmail.com", .calDAV), false),
            (cal("홈", "iCloud", .calDAV), false),
            (cal("캘린더", "나의 iPhone", .local), false),
        ]
        let excluded = CalendarFilter.defaultExcluded(samples.map(\.0))
        #expect(excluded == Set(samples.filter(\.excluded).map(\.0.id)))
    }

    @Test("뺀 캘린더 일정은 kept에서 빠지고 id가 droppedIds에 담긴다")
    func splitEvents() {
        let t = Date(timeIntervalSince1970: 1_780_000_000)
        func event(_ id: String, _ calendarId: String) -> EventInput {
            EventInput(id: id, title: id, start: t, end: t, isRecurring: false, calendarId: calendarId)
        }
        let (kept, dropped) = CalendarFilter.split([event("a", "홈"), event("b", "공휴일"), event("c", "홈")], excluded: ["공휴일"])
        #expect(kept.map(\.id) == ["a", "c"])
        #expect(dropped == ["b"])
    }

    @Test("calendarId를 안 넘기는 기존 호출은 빈 문자열이다")
    func calendarIdDefault() {
        let t = Date(timeIntervalSince1970: 1_780_000_000)
        #expect(EventInput(id: "a", title: "a", start: t, end: t, isRecurring: false).calendarId == "")
    }
}
