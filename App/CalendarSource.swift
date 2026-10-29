import EventKit
import Foundation
#if canImport(WithWhomCore)
import WithWhomCore
#endif

struct CalendarSource {
    enum SourceError: Error { case denied }

    static let excludedKey = "excludedCalendarIds"

    static let knownKey = "knownCalendarIds"

    /// 뺀 캘린더 id. 저장된 값이 없으면 기본값 규칙을 쓴다.
    /// 저장한 뒤에 새로 생긴 캘린더(휴일 캘린더를 새로 구독하거나 id가 바뀐 경우)도 기본값 규칙을 받는다.
    static func excludedIds(for calendars: [CalendarInfo]) -> Set<String> {
        let defaults = UserDefaults.standard
        guard let saved = defaults.stringArray(forKey: excludedKey) else {
            return CalendarFilter.defaultExcluded(calendars)
        }
        guard let known = defaults.stringArray(forKey: knownKey) else { return Set(saved) }
        let unseen = calendars.filter { !known.contains($0.id) }
        return Set(saved).union(CalendarFilter.defaultExcluded(unseen))
    }

    /// 선택과 함께 그때 보인 캘린더 id를 저장해, 다음에 새로 생긴 캘린더를 가려낸다.
    static func saveExcluded(_ ids: Set<String>, calendars: [CalendarInfo]) {
        UserDefaults.standard.set(ids.sorted(), forKey: excludedKey)
        UserDefaults.standard.set(calendars.map(\.id).sorted(), forKey: knownKey)
    }

    private func authorizedStore() async throws -> EKEventStore {
        let store = EKEventStore()
        guard try await store.requestFullAccessToEvents() else { throw SourceError.denied }
        return store
    }

    func calendars() async throws -> [CalendarInfo] {
        Self.info(try await authorizedStore().calendars(for: .event))
    }

    /// 오늘 기준 1년 전 ~ 30일 뒤 일정과 캘린더 목록을 읽는다.
    func read(now: Date = .now) async throws -> (calendars: [CalendarInfo], events: [EventInput]) {
        let store = try await authorizedStore()
        let calendar = Calendar.current
        let from = calendar.date(byAdding: .year, value: -1, to: now)!
        let to = calendar.date(byAdding: .day, value: 30, to: now)!
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: nil)
        let events: [EventInput] = store.events(matching: predicate).compactMap { event in
            // id가 없으면 가져올 때마다 다른 id가 붙어 중복되므로 건너뛴다
            guard let id = event.calendarItemExternalIdentifier ?? event.eventIdentifier else { return nil }
            return EventInput(
                id: id,
                title: event.title ?? "",
                start: event.startDate,
                end: event.endDate,
                isRecurring: event.hasRecurrenceRules,
                calendarId: event.calendar.calendarIdentifier
            )
        }
        return (Self.info(store.calendars(for: .event)), events)
    }

    private static func info(_ calendars: [EKCalendar]) -> [CalendarInfo] {
        calendars.map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title, sourceTitle: $0.source.title, kind: kind($0.type))
        }
    }

    private static func kind(_ type: EKCalendarType) -> CalendarInfo.Kind {
        switch type {
        case .local: .local
        case .calDAV: .calDAV
        case .exchange: .exchange
        case .subscription: .subscription
        case .birthday: .birthday
        @unknown default: .other
        }
    }
}
