import Foundation

public struct CalendarInfo: Sendable, Equatable {
    /// EKCalendarType을 옮긴 값. EventKit 타입을 Core에 들이지 않으려고 따로 둔다.
    public enum Kind: Sendable, Equatable { case local, calDAV, exchange, subscription, birthday, other }

    public var id: String
    public var title: String
    public var sourceTitle: String
    public var kind: Kind

    public init(id: String, title: String, sourceTitle: String, kind: Kind) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
        self.kind = kind
    }
}

public enum CalendarFilter {
    /// 구독·생일 캘린더, 이름에 「휴일」·「holiday」가 든 캘린더를 뺀다.
    public static func defaultExcluded(_ calendars: [CalendarInfo]) -> Set<String> {
        Set(calendars.filter { calendar in
            calendar.kind == .subscription || calendar.kind == .birthday
                || calendar.title.contains("휴일")
                || calendar.title.localizedCaseInsensitiveContains("holiday")
        }.map(\.id))
    }

    /// 뺀 캘린더의 일정을 걸러 내고, 걸러 낸 일정 id를 같이 돌려준다.
    /// 같은 id가 남긴 캘린더에도 있으면(초대받은 일정 등) 지우면 안 되므로 droppedIds에서 뺀다.
    public static func split(_ events: [EventInput], excluded: Set<String>) -> (kept: [EventInput], droppedIds: Set<String>) {
        let kept = events.filter { !excluded.contains($0.calendarId) }
        let dropped = Set(events.filter { excluded.contains($0.calendarId) }.map(\.id))
        return (kept, dropped.subtracting(kept.map(\.id)))
    }

    /// 이미 저장된 일정(existing) 중 뺀 캘린더 때문에 지워야 할 sourceId.
    public static func staleSourceIds(existing: Set<String>, dropped: Set<String>) -> Set<String> {
        existing.intersection(dropped)
    }
}
