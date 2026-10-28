import SwiftData
import SwiftUI

@main
struct WithWhomApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Moment.self, Person.self])
    }
}
