# 156 리뷰 — PR #4

**대상:** `main...HEAD` — 11 commits(리뷰 fix 5개 포함), 15 files, +576 −40 (리뷰 파일 제외)
**plan:** docs/plans/156-1030-plan-pick-person.md

## 지적

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `Core/Sources/WithWhomCore/PersonDictionary.swift:39` | `baseForm`이 한 글자만 남기는 별칭을 만든다. 「아가」를 고르면 별칭 `아`가 되고 「아이 생일」·「아님」까지 그 사람에게 붙는다(실패 징후 2) | fix `6bc310c` |
| 2 | Important | `App/PickPersonView.swift:27` | 별칭 칸에 공백·쉼표가 든 값(「김 가람」)을 저장할 수 있다. 제목은 공백·쉼표에서 나뉘므로 그 별칭은 어떤 제목에도 안 잡히는데 성공 메시지가 나온다 | fix `79113ef` |
| 3 | Important | `Core/Sources/WithWhomCore/TitleParser.swift:27` | 두 번째 ` - `가 있는 제목에서 `-`가 낱말 후보로 나온다. 고르면 별칭 `-`가 저장돼 `-`가 든 모든 제목에 그 사람이 붙는다 | fix `bfd52db` |
| 4 | Important | `Core/Tests/WithWhomCoreTests/TitleParserTests.swift:129` | 화면이 쓰는 `tokens` → `baseForm` → 별칭 → `parse` 왕복을 확인하는 테스트가 없다. 접미사 목록이 한쪽만 바뀌면 고른 낱말이 조용히 안 풀린다 | fix `442d7ab` |
| 5 | Important | `Core/Tests/WithWhomCoreTests/PersonDictionaryTests.swift:108` | `baseForm`이 긴 접미사를 건너뛰고 짧은 접미사로 넘어가는 경우(`이랑`, `이가`)에 테스트가 없다 | fix `6bc310c` |
| 6 | Important | `Core/Sources/WithWhomCore/PersonDictionary.swift:28` | 빈 낱말·빈 이름 별칭을 걸러내는 방어에 테스트가 없다. 빠지면 이름이 빈 `Person`이 생긴다 | fix `a0c644e` |
| 7 | Important | `App/Importer.swift:113` | `reinterpretAll`의 판정 로직(바뀐 일정 수·확인 필요에서 빠진 수·건너뛰는 조건)이 App 타깃 안에 있어 테스트가 없다. Core로 빼면 실패 징후 3(가져오기를 다시 눌러도 결과가 같다)을 테스트로 보일 수 있다 | defer — App 타깃을 건드리는 리팩터링이라 시뮬레이터 확인이 같이 필요하다. 실패 징후 1·3은 어차피 PR 게이트에서 저장 파일로 직접 센다. 후속 티켓에서 `MomentBuilder`로 빼며 테스트를 붙인다 |
| 8 | Important | `App/Importer.swift:144` | 연락처를 못 읽은 가져오기가 기존 일정의 `title`·`items`·`needsReview`도 갱신하지 않는데 안내 문장은 「사람은 그대로 뒀다」만 말한다 | won't-fix — 이 PR이 만든 동작이 아니다. `main`에 같은 분기가 이미 있다(`git show main:App/Importer.swift`의 `keepingPeopleOfExisting`) |
| 9 | Important | `App/Importer.swift:36` | 연락처 접근 거부와 다른 읽기 오류를 구분하지 않고 같은 문장을 낸다. 캘린더 경로(`denied`)처럼 설정에서 허용하라는 안내가 없다 | defer — `run`에 이미 있던 처리이고 이 PR은 같은 꼴을 `pickPerson`에 복사했을 뿐이다. 두 곳을 같이 고치는 후속 티켓이 맞다 |
| 10 | Suggestion | `App/Importer.swift:79` | 한글 낱말의 NFC/NFD 차이로 같은 낱말이 별칭 줄 두 개로 저장될 수 있다. 먼저 읽힌 줄의 사람 이름이 이긴다 | defer — 별칭 데이터를 쓰는 일이라 후속에서 저장 전에 정규화한다. 실제 기기에서 NFD 제목이 나왔다는 증거는 아직 없다 |
| 11 | Suggestion | `App/Models.swift:38` | 별칭을 지우거나 고치는 화면이 없어 잘못 넣은 별칭은 되돌릴 수 없다 | won't-fix — plan 「이번에 안 하는 것」과 설계 「위험」에 적힌 후속 티켓이다 |
| 12 | Suggestion | `App/Importer.swift:17` | `run`과 `pickPerson`이 `isRunning` 하나를 같이 쓴다. 한쪽이 끝나면 다른 쪽이 도는 중에도 가져오기 버튼이 풀린다. 둘 다 메인 액터에서 `await` 없이 저장하므로 데이터는 안 섞인다 | 기록만 |
| 13 | Suggestion | `App/Importer.swift:90` | `pickPerson`이 연락처를 다시 읽어 전체를 다시 해석하므로, 마지막 가져오기 뒤 추가된 연락처로 풀린 일정도 「N개가 다시 해석돼」에 들어간다. 데이터는 일반 가져오기와 같은 결과다 | 기록만 |
| 14 | Suggestion | `App/Importer.swift:165` | `PersonIndex`가 값 타입인데 `ModelContext`(참조)와 캐시를 함께 든다. 복사하면 같은 이름의 `Person`을 두 번 만들 수 있다. 지금 호출부는 지역 변수 하나만 쓴다 | 기록만 |
| 15 | Suggestion | `Core/Sources/WithWhomCore/PersonDictionary.swift:39` | `baseForm` 문서 주석이 접미사를 건너뛰는 동작을 틀리게 설명한다 | fix `6bc310c` |
| 16 | Suggestion | `README.md:22` · `App/Importer.swift:59` · `App/PickPersonView.swift:51` | 주석 넷이 실제보다 넓게 말한다. 「이후 가져오기에서도 별칭이 쓰인다」는 연락처를 읽은 때만이고, `dictionary` 주석의 「같은 사전」도 같다. 사람 숨김 주석은 「일정이 지워져」만 말하지만 일정이 하나도 없는 경우 전부다. 붙여 쓴 제목의 일부(「엄마」)를 직접 입력하면 저장은 되고 아무것도 안 잡힌다 | 기록만 |
| 17 | Suggestion | `App/PickPersonView.swift:84` | `pickPerson`이 입력이 비면 메시지 없이 돌아오고 화면은 결과와 상관없이 시트를 닫는다. 저장 버튼이 막혀 있어 지금은 도달하지 않는다 | 기록만 |
| 18 | Suggestion | `App/Importer.swift:103` | 별칭은 저장했는데 다시 해석이 실패하면 메시지가 「별칭은 남아 있고 가져오기를 누르면 다시 적용된다」를 말하지 않는다. `dictionary`의 별칭 읽기 실패도 「저장하지 못했다」로 나간다(`:51`) | 기록만 |
| 19 | Suggestion | `Core/Tests/WithWhomCoreTests/PersonDictionaryTests.swift` | 연락처 `김나래`(성+이름)와 별칭 `나래` 조합의 우선순위가 정해져 있지 않다. `MomentBuilder.interpret`의 일부만 푸는 경우 직접 테스트도 없다 | 기록만 |
| 20 | Suggestion | `App/Models.swift:38` | `Alias` 모델을 기존 App Group 저장 파일에 추가하는 마이그레이션은 SwiftData 자동 마이그레이션(모델 추가)이라 문서상 문제없지만, 이 리뷰 세션은 옛 저장 파일로 직접 열어 보지 않았다 | 기록만 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| 통과 1: `Core/`에서 `swift test`가 전부 통과한다 | 예 | `swift test` 62개 통과(리뷰 fix 후) |
| 통과 1: 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두) | 예 | fix 후 `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1`, `MEASURE shape=split auto_ok=25/25 review=5 wrong=1` |
| 통과 1: 별칭이 없으면 사전이 지금과 똑같이 동작한다 | 예 | `PersonDictionaryTests`의 별칭 없음 비교 테스트(빈 별칭 사전과 일반 사전이 같은 낱말에서 같은 값) |
| 통과 2: 별칭 테스트(Task 1 표)가 통과한다 | 예 | Task 1 표 6줄 모두에 대응 테스트가 있고 통과. 리뷰에서 테스트 5개를 더 붙였다 |
| 통과 3: 앱이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`), 위젯 appex 포함 | 판정 불가 | 리뷰 세션은 `xcodebuild -target WithWhom -sdk iphonesimulator`가 `BUILD SUCCEEDED`인 것까지만 확인했다. 시뮬레이터 실행(`BOOT_OK`)은 구현 세션의 PR 본문 출력 몫 |
| 통과 4: 확인 필요 탭에서 일정을 누르면 사람 고르기 화면이 열린다 | 판정 불가 | `ContentView.swift`의 `.sheet(item:)`와 `PickPersonView`가 연결돼 있는 것은 코드로 읽었으나 화면을 열어 보지 않았다 |
| 통과 4: 저장하면 별칭이 들어가고 같은 낱말이 든 저장된 일정이 다시 해석된다 | 판정 불가 | `Importer.pickPerson` → `reinterpretAll` 경로를 코드로 읽었다. SwiftData 저장 부분은 App 타깃에 테스트가 없어 실행 증거가 없다(지적 7) |
| 실패 징후 1·3: 별칭 낱말이 든 일정이 전부 풀린다 / 가져오기를 다시 눌러도 같다 | 판정 불가 | PR 게이트에서 main이 기기 저장 파일로 센다. 코드상 가져오기도 같은 `Importer.dictionary`를 쓴다 |
| 실패 징후 2: 별칭 낱말이 없는 일정에 그 사람이 붙지 않는다(0개) | 판정 불가 | 한 글자 별칭(지적 1)과 `-` 별칭(지적 3)이 이 징후를 만들 수 있었고 둘 다 고쳤다. 기기 값은 게이트에서 센다 |
| 실패 징후 4: `MEASURE` 줄 값이 main과 달라지지 않는다 | 예 | 위 `MEASURE` 두 줄 |
| Done: `titles.json`을 고치지 않는다 | 예 | `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다 |

## 확인

- 리뷰 fix 5개를 `git push` 한 번으로 올렸다(`fb98d2e..a0c644e`)
- fix 후 `cd Core && swift test` 62개 통과, 앱 `xcodebuild` `BUILD SUCCEEDED`
- 시뮬레이터 실행(`BOOT_OK`)과 SwiftData 저장 경로 실행은 이 세션에서 하지 않았다
- 인라인 스레드 2건은 올리지 못했다(HTTP 422 `line could not be resolved`): 지적 8(`App/Importer.swift:144`)과 지적 9(`App/Importer.swift:36`). 두 줄이 이 PR의 diff 밖(`main`에 이미 있던 줄)이라 GitHub이 줄을 못 찾았다. 처리 이유는 위 표와 요약 코멘트에 적혀 있다
