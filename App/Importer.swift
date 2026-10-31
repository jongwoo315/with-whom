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
        let drafts: [MomentDraft]
        do {
            // 연락처를 못 읽으면 별칭만 든 사전이 이름 일부만 찾아 반쯤 풀린 일정을 만든다. 빈 사전으로 확인 필요에 보낸다
            let dictionary = contactsLoaded ? try Self.dictionary(contacts: contacts, in: context) : PersonDictionary(contacts: [])
            drafts = MomentBuilder.build(kept, dictionary: dictionary)
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

    /// 연락처 + 저장된 별칭 → 사전. 가져오기와 다시 해석이 같은 사전을 쓴다.
    static func dictionary(contacts: [Contact], in context: ModelContext) throws -> PersonDictionary {
        let aliases = try context.fetch(FetchDescriptor<Alias>())
        return PersonDictionary(contacts: contacts, aliases: Dictionary(aliases.map { ($0.token, $0.personName) }, uniquingKeysWith: { first, _ in first }))
    }

    /// 확인 필요에서 고른 낱말을 별칭으로 저장하고, 저장된 일정을 새 사전으로 다시 해석한다.
    func pickPerson(token: String, personName: String, context: ModelContext) async {
        isRunning = true
        defer { isRunning = false }

        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !personName.isEmpty else { return }
        guard PersonDictionary.isValidAliasKey(token) else {
            message = "별칭 \(token)은 공백이나 쉼표가 들어 있어 저장하지 않았다. 제목의 낱말 하나만 쓸 수 있다."
            return
        }

        do {
            if let alias = try context.fetch(FetchDescriptor<Alias>(predicate: #Predicate { $0.token == token })).first {
                alias.personName = personName
            } else {
                context.insert(Alias(token: token, personName: personName))
            }
            try context.save()
        } catch {
            context.rollback()
            message = "별칭을 저장하지 못했다: \(error.localizedDescription)"
            return
        }

        // 연락처를 못 읽으면 사전이 연락처 없이 만들어져 이미 찾은 사람이 지워진다. 별칭만 남기고 멈춘다
        let contacts: [Contact]
        do {
            contacts = try await ContactsSource().contacts()
        } catch {
            message = "별칭 \(token)을 넣었다. 연락처를 읽지 못해 이미 가져온 일정은 다시 해석하지 않았다."
            return
        }

        do {
            let result = try reinterpretAll(dictionary: Self.dictionary(contacts: contacts, in: context), in: context)
            message = "별칭 \(token)을 넣었다. 일정 \(result.changed)개가 다시 해석돼 확인 필요에서 \(result.resolved)개가 빠졌다."
        } catch {
            context.rollback()
            message = "별칭 \(token)을 넣었지만 일정을 다시 해석하지 못했다: \(error.localizedDescription)"
            return
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 저장된 Moment 전부를 사전으로 다시 해석한다. 캘린더는 다시 읽지 않는다.
    /// changed: 사람·항목·확인 필요 중 하나라도 달라진 일정 수, resolved: 확인 필요에서 빠진 일정 수.
    private func reinterpretAll(dictionary: PersonDictionary, in context: ModelContext) throws -> (changed: Int, resolved: Int) {
        var index = try PersonIndex(context: context)
        var changed = 0, resolved = 0
        for moment in try context.fetch(FetchDescriptor<Moment>()) {
            let result = MomentBuilder.interpret(moment.title, dictionary: dictionary)
            if Set(moment.people.map(\.name)) == result.people, moment.items == result.items, moment.needsReview == result.needsReview { continue }
            changed += 1
            if moment.needsReview && !result.needsReview { resolved += 1 }
            moment.items = result.items
            moment.needsReview = result.needsReview
            moment.people = result.people.sorted().map { index.person(named: $0) }
        }
        try context.save()
        return (changed, resolved)
    }

    private func upsert(_ drafts: [MomentDraft], droppingSourceIds droppedIds: Set<String>, keepingPeopleOfExisting: Bool, into context: ModelContext) throws {
        var moments = Dictionary(try context.fetch(FetchDescriptor<Moment>()).map { ($0.sourceId, $0) }, uniquingKeysWith: { first, _ in first })
        // 뺀 캘린더의 일정으로 이미 들어와 있던 것은 지운다. 비게 된 Person은 사람 목록 화면이 숨긴다
        for id in CalendarFilter.staleSourceIds(existing: Set(moments.keys), dropped: droppedIds) {
            if let moment = moments.removeValue(forKey: id) { context.delete(moment) }
        }
        var index = try PersonIndex(context: context)

        for draft in drafts {
            let people = draft.people.sorted().map { index.person(named: $0) }
            if let moment = moments[draft.sourceId] {
                moment.date = draft.date
                moment.start = draft.start
                moment.end = draft.end
                // 장소를 모르는 가져오기가 저장된 장소를 지우지 않게 한다
                if let place = draft.place { apply(place, to: moment) }
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
                if let place = draft.place { apply(place, to: moment) }
                moments[draft.sourceId] = moment
            }
        }
        try context.save()
    }

    private func apply(_ place: Place, to moment: Moment) {
        moment.placeName = place.name
        moment.latitude = place.latitude
        moment.longitude = place.longitude
    }
}

/// 이름 → Person. 없는 이름은 만들어 넣는다. 가져오기와 다시 해석이 같이 쓴다.
struct PersonIndex {
    private var persons: [String: Person]
    private let context: ModelContext

    init(context: ModelContext) throws {
        self.context = context
        persons = Dictionary(try context.fetch(FetchDescriptor<Person>()).map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    }

    mutating func person(named name: String) -> Person {
        if let person = persons[name] { return person }
        let person = Person(name: name)
        context.insert(person)
        persons[name] = person
        return person
    }
}
