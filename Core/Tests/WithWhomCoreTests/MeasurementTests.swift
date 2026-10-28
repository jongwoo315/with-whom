import Foundation
import Testing
@testable import WithWhomCore

private struct Fixture: Decodable {
    struct Shape: Decodable { let given: String; let family: String }
    struct Case: Decodable {
        let n: Int
        let title: String
        let expect: String
        let people: [String]
        let items: [String]
    }
    let contactShapes: [String: [Shape]]
    let cases: [Case]
}

/// 정답 파일로 제목 해석을 잰다. 임계값으로 실패시키지 않는다 — 파일 형식이 깨졌을 때만 실패한다.
struct MeasurementTests {
    private static func loadFixture() throws -> Fixture {
        let url = try #require(Bundle.module.url(forResource: "titles", withExtension: "json"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    @Test("견본 31개를 연락처 꼴별로 잰다", arguments: ["split", "fullInGiven"])
    func measure(shape: String) throws {
        let fixture = try Self.loadFixture()
        let shapes = try #require(fixture.contactShapes[shape])
        #expect(fixture.cases.count == 31)
        let dictionary = PersonDictionary(contacts: shapes.map { Contact(given: $0.given, family: $0.family) })

        var autoOK = 0, review = 0, wrong = 0
        for c in fixture.cases {
            let result = TitleParser.parse(c.title, dictionary: dictionary)
            let verdict: String
            switch result {
            case .review:
                review += 1
                verdict = "review"
            case .auto(let people, let items):
                if c.expect == "auto", people == Set(c.people), items == c.items {
                    autoOK += 1
                    verdict = "auto_ok"
                } else {
                    wrong += 1
                    verdict = "wrong"
                }
            }
            print("CASE shape=\(shape) n=\(c.n) \(verdict) got=\(result) expect=\(c.expect) people=\(c.people) items=\(c.items)")
        }
        let autoTotal = fixture.cases.filter { $0.expect == "auto" }.count
        print("MEASURE shape=\(shape) auto_ok=\(autoOK)/\(autoTotal) review=\(review) wrong=\(wrong)")
    }
}
