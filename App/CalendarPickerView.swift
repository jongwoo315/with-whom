import SwiftUI
#if canImport(WithWhomCore)
import WithWhomCore
#endif

/// 어느 캘린더를 읽을지 고르는 화면. 스위치를 바꾸면 바로 저장하고, 가져오기는 시트를 닫을 때 ContentView가 다시 돌린다.
struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var calendars: [CalendarInfo] = []
    @State private var excluded: Set<String> = []
    @State private var problem: String?

    var body: some View {
        NavigationStack {
            List {
                if let problem {
                    Text(problem)
                }
                ForEach(groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.calendars, id: \.id) { calendar in
                            Toggle(calendar.title, isOn: binding(for: calendar))
                        }
                    }
                }
            }
            .navigationTitle("캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("닫기") { dismiss() } }
            }
        }
        .task { await load() }
    }

    private var groups: [(title: String, calendars: [CalendarInfo])] {
        Dictionary(grouping: calendars, by: \.sourceTitle)
            .map { (title: $0.key, calendars: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.title < $1.title }
    }

    private func binding(for calendar: CalendarInfo) -> Binding<Bool> {
        Binding(
            get: { !excluded.contains(calendar.id) },
            set: { isOn in
                if isOn { excluded.remove(calendar.id) } else { excluded.insert(calendar.id) }
                CalendarSource.saveExcluded(excluded, calendars: calendars)
            }
        )
    }

    private func load() async {
        do {
            calendars = try await CalendarSource().calendars()
            excluded = CalendarSource.excludedIds(for: calendars)
        } catch CalendarSource.SourceError.denied {
            problem = "캘린더 권한이 없어 목록을 보여 줄 수 없다. 설정에서 캘린더 접근을 허용하면 된다."
        } catch {
            problem = "캘린더 목록을 읽지 못했다: \(error.localizedDescription)"
        }
    }
}
