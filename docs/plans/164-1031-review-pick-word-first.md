# 164 리뷰 — PR #6

**대상:** `main...HEAD` — 6 commits, 9 files, +291 −20 (이 리뷰 파일 제외)
**plan:** docs/plans/164-1031-plan-pick-word-first.md

## 지적

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `Core/Tests/WithWhomCoreTests/PickRuleTests.swift:10` | 표에 「별칭이 잘못됐고 이름도 빈 칸」 행이 없어, `PickRule.swift`의 두 검사 순서를 바꿔도 테스트가 모두 통과한다 | fix `93bf57c` |
| 2 | Important | `App/PickPersonView.swift:63` | 고른 사람의 일정이 시트가 열려 있는 동안 모두 지워지면 목록에서는 숨는데 `existingName`은 그대로라, 체크 표시가 안 보이는 사람에게 별칭이 저장된다. main에도 있는 동작이다 | defer — 이 티켓은 저장 로직을 안 바꾼다(plan 이번에 안 하는 것). 별칭 저장 쪽 검증은 따로 티켓이 필요하다 |
| 3 | Suggestion | `Core/Tests/WithWhomCoreTests/PickRuleTests.swift:28` | 이전 조건과 같다는 테스트가 표와 같은 입력 10개만 돌고, 양쪽이 같은 `isValidAliasKey`를 불러서 그 함수가 바뀌면 둘이 같이 바뀐다. 탭·줄바꿈·쉼표 위치 변형 행도 없다 | 기록만 |
| 4 | Suggestion | `README.md:28` | 「낱말을 먼저 고르면(별칭 칸이 유효해지면)」은 별칭 칸에 직접 적어도 열린다는 것과 「유효」의 뜻(비지 않고 띄어쓰기·쉼표가 없다)을 말하지 않는다 | 기록만 |
| 5 | Suggestion | `Core/Sources/WithWhomCore/PickRule.swift:3` | 문서 주석이 「저장 버튼 상태」가 이 함수에서 나온다고 하지만 저장 중 비활성(`isSaving`)은 화면이 따로 본다 | 기록만 |
| 6 | Suggestion | `Core/Sources/WithWhomCore/PickRule.swift:9` | 문장 1의 「위에서」가 화면 배치를 Core에 박아 둔다. 배치가 바뀌면 컴파일 오류 없이 문장이 틀어진다 | 기록만 |
| 7 | Suggestion | `App/PickPersonView.swift:90` | 별칭이 빈 칸이면 「위에서 낱말을 먼저 고른다」와 「위에서 낱말을 고르거나 별칭을 적어야 저장할 수 있다」가 연달아 나와 거의 같은 말이 두 번 보이고, 별칭이 「김 가람」이면 윗줄은 낱말을 고르라고 하는데 실제 이유는 띄어쓰기다. plan이 두 줄을 모두 지정했다 | 기록만 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| 통과 기준 1: `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다 | 예 | 리뷰 세션이 직접 돌렸다. `Test run with 66 tests in 7 suites passed`, `MEASURE shape=split auto_ok=25/25 review=5 wrong=1`, `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1` |
| 통과 기준 2: `PickRule.blockReason` 테스트(Task 1 표)가 통과한다 | 예 | `Core/Tests/WithWhomCoreTests/PickRuleTests.swift`의 표 8행 + 리뷰에서 더한 2행, `PickRuleTests` 통과 |
| 통과 기준 3: 앱과 위젯이 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`) | 판정 불가 | PR 본문이 `BOOT_OK`와 appex 경로를 적었다. 리뷰 세션은 빌드·실행을 다시 하지 않았다 |
| 통과 기준 4: 스크린샷 셋이 PR 본문에 경로와 함께 있다 | 예 | PR 본문 `## Notes`에 경로 3개. 세 파일이 있고 리뷰 세션이 열어 봤다 |
| 실패 징후 1 (가): 낱말을 고르기 전 화면에 「누구인가」 칸이 없다 | 값만 적는다 | 스크린샷 1(별칭 빈 칸)에 「누구인가」 구역·「새 사람」·이름 칸이 보이지 않고 「위에서 낱말을 먼저 고른다」 한 줄이 보인다 |
| 실패 징후 1 (나): 막히는 세 경우마다 다른 이유 문장 | 값만 적는다 | 테스트 3/3(문장 1·2·3이 서로 다르다). 화면은 스크린샷 1(「위에서 낱말을 고르거나 별칭을 적어야 저장할 수 있다」)과 3(「별칭에는 띄어쓰기와 쉼표를 넣을 수 없다」) 2/2 |
| 실패 징후 1 (다): 저장할 수 있는 상태에서 이유 문장이 없고 저장 버튼이 눌린다 | 값만 적는다 | 스크린샷 2(별칭 `가람`)에 이유 문장이 없고 「누구인가」가 열려 있으며 저장 글자가 진하다. 스크린샷 1·3은 저장 글자가 흐리다 |
| 실패 징후 2: `blockReason == nil`과 main의 `canSave` 조건이 표 입력 전부에서 같다 | 예 | `PickRuleTests.swift:29` `sameAsOldCanSave`, 표 10행 모두 통과. 코드로도 `PersonDictionary.swift:34`가 빈 문자열을 이미 거절해, 새 빈 칸 검사는 문장만 고른다 |
| 실패 징후 3: `MEASURE` 값이 main과 달라졌다 | 아니오(달라지지 않았다) | 위 통과 기준 1의 두 줄이 plan에 적힌 main 값과 같다 |
| 이번에 안 하는 것: `Importer.pickPerson` 변경 없음 | 예 | `git diff --stat main...HEAD` 파일 목록에 `Importer`가 없다 |
| Done: `titles.json`을 고치지 않는다 | 예 | `git diff --stat main...HEAD`에 `titles.json`이 없다 |
| Done: PR 본문 맨 위 `## 착수 전 기준 (jw)` 절 | 예 | PR 본문 첫 절 |
| Done: 커밋 접두사는 표의 것, 괄호 없음, 한글 | 예 | `git log --oneline main..HEAD` 6줄 모두 `feature:`·`add:`·`docs:`·`test:` + 한글 |

## 처리 메모

- 리뷰는 `pr-review-toolkit`의 code-reviewer·pr-test-analyzer·comment-analyzer 세 에이전트로 했다. 에러 처리와 새 타입 설계 변경이 없어(`PickRule`은 정적 함수 하나인 `enum`) silent-failure-hunter·type-design-analyzer는 돌리지 않았다
- 지적 1을 고친 뒤 `swift test`를 다시 돌려 통과를 확인했다
