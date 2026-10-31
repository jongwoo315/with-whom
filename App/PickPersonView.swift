import SwiftData
import SwiftUI
#if canImport(WithWhomCore)
import WithWhomCore
#endif

/// 확인 필요 일정의 제목에서 낱말 하나를 골라 어느 사람인지 정하는 화면. 저장하면 별칭이 들어가고 저장된 일정이 다시 해석된다.
struct PickPersonView: View {
    /// 시트가 열려 있는 동안 일정이 지워져도 읽을 수 있게 값으로 받는다
    let title: String
    let importer: Importer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.name) private var people: [Person]
    @State private var alias = ""
    @State private var existingName: String?
    /// nil이면 별칭 칸 값을 따라간다
    @State private var newName: String?
    @State private var isSaving = false

    private var isNewPerson: Bool { existingName == nil }
    private var personName: String {
        (isNewPerson ? (newName ?? alias) : existingName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedAlias: String { alias.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var blockReason: String? { PickRule.blockReason(alias: alias, personName: personName) }
    private var canSave: Bool { blockReason == nil && !isSaving }

    var body: some View {
        NavigationStack {
            Form {
                Section("일정 제목") {
                    Text(title)
                }
                Section("어느 낱말인가") {
                    ForEach(TitleParser.tokens(title), id: \.self) { token in
                        Button {
                            alias = PersonDictionary.baseForm(token)
                        } label: {
                            HStack {
                                Text(token)
                                Spacer()
                                if PersonDictionary.baseForm(token) == trimmedAlias { Image(systemName: "checkmark") }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    TextField("별칭", text: $alias)
                }
                if PersonDictionary.isValidAliasKey(trimmedAlias) {
                    Section("누구인가") {
                        // 일정이 모두 지워져 사람 목록 화면이 숨기는 사람은 고를 수 없게 같이 숨긴다
                        ForEach(people.filter { !$0.moments.isEmpty }) { person in
                            Button {
                                existingName = person.name
                            } label: {
                                HStack {
                                    Text(person.name)
                                    Spacer()
                                    if existingName == person.name { Image(systemName: "checkmark") }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                        Button {
                            existingName = nil
                        } label: {
                            HStack {
                                Text("새 사람")
                                Spacer()
                                if isNewPerson { Image(systemName: "checkmark") }
                            }
                        }
                        .foregroundStyle(.primary)
                        if isNewPerson {
                            TextField("이름", text: Binding(get: { newName ?? alias }, set: { newName = $0 }))
                        }
                    }
                } else {
                    Section { Text("위에서 낱말을 먼저 고른다").foregroundStyle(.secondary) }
                }
                if let reason = blockReason {
                    Section { Text(reason).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("사람 고르기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        isSaving = true
                        Task {
                            await importer.pickPerson(token: trimmedAlias, personName: personName, context: context)
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
