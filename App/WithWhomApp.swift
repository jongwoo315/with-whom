import SwiftData
import SwiftUI

@main
struct WithWhomApp: App {
    let container: ModelContainer

    init() {
        // 대체 경로를 두지 않는다. App Group이 깨졌는데 앱만 멀쩡해 보이면 위젯만 비는 걸 늦게 안다
        do {
            container = try SharedStore.makeContainer()
        } catch {
            fatalError("저장 파일을 만들지 못했다: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
