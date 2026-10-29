import SwiftData
import SwiftUI
import WidgetKit
#if canImport(WithWhomCore)
import WithWhomCore
#endif

struct UnseenEntry: TimelineEntry {
    let date: Date
    /// 고른 사람이 없으면 nil
    let pick: (name: String, days: Int)?
}

struct UnseenProvider: TimelineProvider {
    private static let sample = UnseenEntry(date: .now, pick: (name: "가람", days: 12))

    func placeholder(in context: Context) -> UnseenEntry { Self.sample }

    func getSnapshot(in context: Context, completion: @escaping (UnseenEntry) -> Void) {
        completion(Self.sample)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UnseenEntry>) -> Void) {
        let now = Date.now
        let entry = UnseenEntry(date: now, pick: Self.load(now: now))
        // 날 수는 하루에 한 번 바뀐다. 다음 날 0시에 다시 만든다
        let nextMidnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    /// 컨테이너를 못 만들거나 읽지 못하면 nil → 「아직 만난 사람이 없다」 화면
    private static func load(now: Date) -> (name: String, days: Int)? {
        guard let container = try? SharedStore.makeContainer() else { return nil }
        // context는 container를 붙잡지 않으므로 읽는 동안 container를 살려 둔다
        return withExtendedLifetime(container) {
            let context = ModelContext(container)
            guard let people = try? context.fetch(FetchDescriptor<Person>()) else { return nil }
            let lastSeen: [(name: String, last: Date)] = people.compactMap { person in
                guard let last = person.moments.map(\.start).filter({ $0 <= now }).max() else { return nil }
                return (name: person.name, last: last)
            }
            return LongestUnseen.pick(lastSeen, now: now, calendar: .current)
        }
    }
}

struct UnseenWidgetView: View {
    let entry: UnseenEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let pick = entry.pick {
                Text(pick.name)
                    .font(.title)
                    .bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("\(pick.days)일째 못 봄")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("아직 만난 사람이 없다")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct UnseenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UnseenWidget", provider: UnseenProvider()) { entry in
            UnseenWidgetView(entry: entry)
        }
        .configurationDisplayName("오래 못 본 사람")
        .description("가장 오래 만나지 못한 사람과 지난 날 수를 보여 준다.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct WithWhomWidgetBundle: WidgetBundle {
    var body: some Widget {
        UnseenWidget()
    }
}
