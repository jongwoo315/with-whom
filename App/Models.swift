import Foundation
import SwiftData

@Model
final class Moment {
    @Attribute(.unique) var sourceId: String
    var date: Date
    var start: Date
    var end: Date
    var title: String
    var items: [String]
    var needsReview: Bool
    @Relationship(inverse: \Person.moments) var people: [Person] = []

    init(sourceId: String, date: Date, start: Date, end: Date, title: String, items: [String], needsReview: Bool) {
        self.sourceId = sourceId
        self.date = date
        self.start = start
        self.end = end
        self.title = title
        self.items = items
        self.needsReview = needsReview
    }
}

@Model
final class Person {
    @Attribute(.unique) var name: String
    var moments: [Moment] = []

    init(name: String) {
        self.name = name
    }
}

/// 앱과 위젯이 같은 저장 파일을 쓰려고 App Group 폴더에 컨테이너를 만든다.
enum SharedStore {
    static let groupId = "group.com.jongwoo315.withwhom"

    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Moment.self, Person.self,
            configurations: ModelConfiguration(groupContainer: .identifier(groupId))
        )
    }
}
