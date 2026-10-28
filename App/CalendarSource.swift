import EventKit
#if canImport(WithWhomCore)
import WithWhomCore
#endif

struct CalendarSource {
    enum SourceError: Error { case denied }

    /// 오늘 기준 1년 전 ~ 30일 뒤 일정을 읽는다.
    func events(now: Date = .now) async throws -> [EventInput] {
        let store = EKEventStore()
        guard try await store.requestFullAccessToEvents() else { throw SourceError.denied }
        let calendar = Calendar.current
        let from = calendar.date(byAdding: .year, value: -1, to: now)!
        let to = calendar.date(byAdding: .day, value: 30, to: now)!
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: nil)
        return store.events(matching: predicate).map { event in
            EventInput(
                id: event.calendarItemExternalIdentifier ?? event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "",
                start: event.startDate,
                end: event.endDate,
                isRecurring: event.hasRecurrenceRules
            )
        }
    }
}
