import Foundation

/// 사람 고르기 화면의 저장 조건. 저장 버튼 상태와 막힌 이유 문장이 한 함수에서 나온다.
public enum PickRule {
    /// 저장할 수 있으면 `nil`, 막혔으면 무엇을 하면 풀리는지 적은 문장.
    public static func blockReason(alias: String, personName: String) -> String? {
        let alias = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let personName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        if alias.isEmpty { return "위에서 낱말을 고르거나 별칭을 적어야 저장할 수 있다" }
        if !PersonDictionary.isValidAliasKey(alias) { return "별칭에는 띄어쓰기와 쉼표를 넣을 수 없다" }
        if personName.isEmpty { return "새 사람 이름을 적어야 저장할 수 있다" }
        return nil
    }
}
