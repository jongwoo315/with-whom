import Foundation

public struct EventInput: Sendable, Equatable {
    public var id: String
    public var title: String
    public var start: Date
    public var end: Date
    public var isRecurring: Bool
    public var calendarId: String

    public init(id: String, title: String, start: Date, end: Date, isRecurring: Bool, calendarId: String = "") {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isRecurring = isRecurring
        self.calendarId = calendarId
    }
}

public struct MomentDraft: Sendable, Equatable {
    public var sourceId: String
    public var date: Date
    public var start: Date
    public var end: Date
    public var title: String
    public var people: Set<String>
    public var items: [String]
    public var needsReview: Bool
}

public enum MomentBuilder {
    /// 반복 일정을 빼고, 같은 id는 먼저 온 것만 남기고, 제목을 해석해 초안을 만든다.
    public static func build(
        _ events: [EventInput],
        dictionary: PersonDictionary,
        calendar: Calendar = .current
    ) -> [MomentDraft] {
        var seen = Set<String>()
        return events.compactMap { event in
            guard !event.isRecurring, seen.insert(event.id).inserted else { return nil }
            let people: Set<String>, items: [String], needsReview: Bool
            switch TitleParser.parse(event.title, dictionary: dictionary) {
            case .auto(let p, let i): (people, items, needsReview) = (p, i, false)
            case .review(let i): (people, items, needsReview) = ([], i, true)
            }
            return MomentDraft(
                sourceId: event.id, date: calendar.startOfDay(for: event.start),
                start: event.start, end: event.end, title: event.title,
                people: people, items: items, needsReview: needsReview
            )
        }
    }
}
