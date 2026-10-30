import Foundation
import Observation
import SwiftData
import WidgetKit
#if canImport(WithWhomCore)
import WithWhomCore
#endif

@MainActor
@Observable
final class Importer {
    private(set) var isRunning = false
    private(set) var message = ""

    /// 일정 → 반복 제외 → 제목 해석 → SwiftData 저장. 권한이 없으면 문장으로 알리고 멈춘다.
    func run(context: ModelContext) async {
        isRunning = true
        defer { isRunning = false }

        let calendars: [CalendarInfo], events: [EventInput]
        do {
            (calendars, events) = try await CalendarSource().read()
        } catch CalendarSource.SourceError.denied {
            message = "캘린더 권한이 없어 일정을 가져오지 못했다. 설정에서 캘린더 접근을 허용하면 된다."
            return
        } catch {
            message = "일정을 읽지 못했다: \(error.localizedDescription)"
            return
        }

        var contacts: [Contact] = []
        var notice = ""
        var contactsLoaded = true
        do {
            contacts = try await ContactsSource().contacts()
        } catch {
            contactsLoaded = false
            notice = " 연락처를 읽지 못해 사람을 찾지 못했다. 새 일정은 확인 필요로 들어갔고, 이미 가져온 일정의 사람은 그대로 뒀다."
        }

        let excluded = CalendarSource.excludedIds(for: calendars)
        let (kept, droppedIds) = CalendarFilter.split(events, excluded: excluded)
        let drafts = MomentBuilder.build(kept, dictionary: PersonDictionary(contacts: contacts))
        do {
            try upsert(drafts, droppingSourceIds: droppedIds, keepingPeopleOfExisting: !contactsLoaded, into: context)
        } catch {
            context.rollback()
            message = "저장하지 못했다: \(error.localizedDescription)"
            return
        }
        WidgetCenter.shared.reloadAllTimelines()
        let skipped = droppedIds.isEmpty ? "" : " 뺀 캘린더 일정 \(droppedIds.count)개는 넣지 않았다."
        message = "일정 \(drafts.count)개를 가져왔다.\(skipped)\(notice)"
    }

    private func upsert(_ drafts: [MomentDraft], droppingSourceIds droppedIds: Set<String>, keepingPeopleOfExisting: Bool, into context: ModelContext) throws {
        var moments = Dictionary(try context.fetch(FetchDescriptor<Moment>()).map { ($0.sourceId, $0) }, uniquingKeysWith: { first, _ in first })
        // 뺀 캘린더의 일정으로 이미 들어와 있던 것은 지운다. 비게 된 Person은 사람 목록 화면이 숨긴다
        for id in CalendarFilter.staleSourceIds(existing: Set(moments.keys), dropped: droppedIds) {
            if let moment = moments.removeValue(forKey: id) { context.delete(moment) }
        }
        var persons = Dictionary(try context.fetch(FetchDescriptor<Person>()).map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

        for draft in drafts {
            let people = draft.people.sorted().map { name in
                persons[name] ?? {
                    let person = Person(name: name)
                    context.insert(person)
                    persons[name] = person
                    return person
                }()
            }
            if let moment = moments[draft.sourceId] {
                moment.date = draft.date
                moment.start = draft.start
                moment.end = draft.end
                // 연락처를 못 읽은 실행의 빈 사람 목록이 이미 찾아 둔 사람을 지우지 않게 한다
                if !keepingPeopleOfExisting {
                    moment.title = draft.title
                    moment.items = draft.items
                    moment.needsReview = draft.needsReview
                    moment.people = people
                }
            } else {
                let moment = Moment(
                    sourceId: draft.sourceId, date: draft.date, start: draft.start, end: draft.end,
                    title: draft.title, items: draft.items, needsReview: draft.needsReview
                )
                context.insert(moment)
                moment.people = people
                moments[draft.sourceId] = moment
            }
        }
        try context.save()
    }
}
