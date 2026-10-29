import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var importer = Importer()
    @State private var showsCalendars = false

    var body: some View {
        TabView {
            tab("사람별", systemImage: "person.2") { PeopleView() }
            tab("날짜별", systemImage: "calendar") { DatesView() }
            tab("확인 필요", systemImage: "questionmark.circle") { ReviewView() }
        }
        // 시트를 닫으면 가져오기를 다시 돌려, 끈 캘린더의 일정이 바로 지워지게 한다
        .sheet(isPresented: $showsCalendars, onDismiss: { Task { await importer.run(context: context) } }) {
            CalendarPickerView()
        }
        #if DEBUG
        // 시뮬레이터에서 버튼 탭 없이 가져오기를 돌려 보려는 확인용: simctl launch ... -autoImport
        .task { if CommandLine.arguments.contains("-autoImport") { await importer.run(context: context) } }
        #endif
    }

    private func tab<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .navigationTitle(title)
                .safeAreaInset(edge: .bottom) {
                    if !importer.message.isEmpty {
                        Text(importer.message)
                            .font(.footnote)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(.regularMaterial)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("캘린더") { showsCalendars = true }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("가져오기") { Task { await importer.run(context: context) } }
                            .disabled(importer.isRunning)
                    }
                }
        }
        .tabItem { Label(title, systemImage: systemImage) }
    }
}

struct MomentRow: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(moment.date, format: .dateTime.year().month().day())
                .font(.caption).foregroundStyle(.secondary)
            if !moment.people.isEmpty {
                Text(moment.people.map(\.name).sorted().joined(separator: ", ")).font(.headline)
            }
            Text(moment.items.isEmpty ? moment.title : moment.items.joined(separator: " · "))
        }
    }
}

struct PeopleView: View {
    @Query(sort: \Person.name) private var people: [Person]

    var body: some View {
        let visible = people.filter { !$0.moments.isEmpty }
        List(visible) { person in
            NavigationLink("\(person.name) (\(person.moments.count))") {
                List(person.moments.sorted { $0.start > $1.start }) { MomentRow(moment: $0) }
                    .navigationTitle(person.name)
            }
        }
        .overlay { if visible.isEmpty { ContentUnavailableView("아직 사람이 없다", systemImage: "person.2", description: Text("「가져오기」를 누르면 일정에서 뽑는다.")) } }
    }
}

struct DatesView: View {
    @Query(sort: \Moment.start, order: .reverse) private var moments: [Moment]

    var body: some View {
        List(moments) { MomentRow(moment: $0) }
            .overlay { if moments.isEmpty { ContentUnavailableView("아직 일정이 없다", systemImage: "calendar", description: Text("「가져오기」를 누르면 일정에서 뽑는다.")) } }
    }
}

struct ReviewView: View {
    @Query(filter: #Predicate<Moment> { $0.needsReview }, sort: \Moment.start, order: .reverse)
    private var moments: [Moment]

    var body: some View {
        List(moments) { MomentRow(moment: $0) }
            .overlay { if moments.isEmpty { ContentUnavailableView("확인할 일정이 없다", systemImage: "checkmark.circle") } }
    }
}
