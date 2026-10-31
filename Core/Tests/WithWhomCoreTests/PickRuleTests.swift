import Foundation
import Testing
@testable import WithWhomCore

struct PickRuleTests {
    static let aliasEmpty = "위에서 낱말을 고르거나 별칭을 적어야 저장할 수 있다"
    static let aliasInvalid = "별칭에는 띄어쓰기와 쉼표를 넣을 수 없다"
    static let nameEmpty = "새 사람 이름을 적어야 저장할 수 있다"

    static let cases: [(alias: String, personName: String, reason: String?)] = [
        ("", "", aliasEmpty),
        ("  ", "가람", aliasEmpty),
        ("김 가람", "가람", aliasInvalid),
        ("가람,", "가람", aliasInvalid),
        ("김 가람", "", aliasInvalid),
        ("  ", "", aliasEmpty),
        ("가람", "", nameEmpty),
        ("가람", "  ", nameEmpty),
        ("가람", "가람", nil),
        (" 가람 ", "나래", nil),
    ]

    @Test("저장을 막는 이유가 경우마다 다른 문장으로 나온다", arguments: cases)
    func reason(_ c: (alias: String, personName: String, reason: String?)) {
        #expect(PickRule.blockReason(alias: c.alias, personName: c.personName) == c.reason)
    }

    @Test("blockReason이 nil인 입력은 이전 저장 조건과 같다")
    func sameAsOldCanSave() {
        for c in Self.cases {
            let alias = c.alias.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = c.personName.trimmingCharacters(in: .whitespacesAndNewlines)
            let old = PersonDictionary.isValidAliasKey(alias) && !name.isEmpty
            #expect((PickRule.blockReason(alias: c.alias, personName: c.personName) == nil) == old)
        }
    }
}
