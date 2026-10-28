# 154 리뷰 — PR #1

**대상:** `main...HEAD` — 11 commits, 24 files, +1394 −8 (리뷰 fix 3커밋 포함)
**plan:** docs/plans/154-1028-plan-calendar-skeleton.md

## 지적

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `App/Importer.swift:30` | 연락처를 못 읽은 실행(권한을 끈 경우·`CNError`)이 `people = []`·`needsReview = true`로 이미 가져온 일정의 사람 연결을 전부 지우고 확인 필요로 보낸다 | fix `2adae26` |
| 2 | Important | `App/Importer.swift:21` | 캘린더 읽기 오류가 전부 「권한이 없다」로 안내된다. 권한 거부가 아닌 EventKit 오류에도 설정으로 가라고 한다 | fix `0ef75de` |
| 3 | Important | `Core/Tests/WithWhomCoreTests/TitleParserTests.swift:74` | plan 규칙 「사람이 없으면 항목은 제목 전체 하나」가 ` - `가 든 제목에서는 테스트가 없다 | fix `cf9a686` |
| 4 | Important | `project.yml:14` | plan Task 4는 `Core`를 local package 의존으로 쓰라고 했는데 앱 target에 Core 소스를 직접 넣었다 | won't-fix — 작성자가 package 의존 시 이 기기(Xcode 26.5 + iOS 26.2 런타임만)에서 빌드 destination이 안 잡혔다고 README에 적었다. 이 세션에서는 그 재현을 하지 않았다. 직접 포함 구성으로 plan Pre-PR의 `-scheme`/`-destination` 빌드는 성공한다 (`BUILD SUCCEEDED`). 의존 방식 복귀는 사람이 정한다 |
| 5 | Suggestion | `App/Importer.swift:51` | upsert가 삭제를 반영하지 않는다. 캘린더에서 지운 일정·반복으로 바뀐 일정이 앱에 계속 남는다 | defer — 이번 plan 범위(가져오기 한 번)에 삭제 동기화가 없다. 데이터를 지우는 동작이라 어떤 일정을 지울지 정하고 들어가야 한다 |
| 6 | Suggestion | `App/ContentView.swift:25` | 다시 가져오는 동안 이전 실행의 결과 메시지가 그대로 보이고 진행 표시가 없다 | 기록만 |
| 7 | Suggestion | `Core/Tests/WithWhomCoreTests/MeasurementTests.swift:29` | `expect` 값(`auto`/`review`)과 분모 25를 검사하지 않아 정답 파일 오타가 조용히 `wrong`으로 센다 | 기록만 |
| 8 | Suggestion | `Core/Sources/WithWhomCore/PersonDictionary.swift:25` | 이름이 같은 연락처 둘이면 먼저 온 쪽만 사전에 남는다(`김가람`·`이가람` → `가람`). 동작은 의도적이나 테스트가 없다 | 기록만 |
| 9 | Suggestion | `App/Importer.swift:47` | 앱 target에 테스트 target이 없어 Importer·소스 쪽 수정(중복 키 방지·롤백)이 `swift test`로 안 잡힌다 | 기록만 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| 통과 기준 1: `swift test`가 전부 통과한다 | 예 | 28 tests passed (리뷰 fix 후) |
| 통과 기준 2: 연락처 꼴 둘로 `MEASURE` 줄을 출력한다 | 예 | `MEASURE shape=split auto_ok=25/25 review=5 wrong=1` · `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1` (`MeasurementTests.swift:52`) |
| 통과 기준 3: iPhone 17 Pro 시뮬레이터용으로 빌드된다 | 예 | `xcodebuild -scheme WithWhom -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → `BUILD SUCCEEDED`. 설치·실행은 이 세션에서 하지 않았다 |
| 통과 기준 4: 「가져오기」가 일정 → 해석 → 저장 → 세 목록으로 한 번에 진행된다 | 판정 불가 | 코드 경로는 `App/Importer.swift:17-49`, `App/ContentView.swift`. UI 실행은 하지 않았다 |
| 실패 징후 1: 나쁜 쪽 값 `auto_ok` 24 이상이고 `wrong` 1 이하면 통과 구간 | 값만 적는다 | 두 꼴 모두 `auto_ok=25` `wrong=1`. `wrong` 1건은 n=26(정답 `review`, 돌려준 값 `auto(people: [바다, 세라], items: [자기가 만나는 날])`). 구간 판정은 사람이 한다 |
| 실패 징후 2: `titles.json`을 구현 쪽에서 고치지 않았다 | 예 | `git log -- titles.json` = `f589a80` 하나. `git diff main...HEAD`에서 착수 커밋 이후 변경 없음 |
| 실패 징후 3: `wrong`이 0인데 `review`가 6보다 크지 않다 | 예 | `wrong=1`이라 해당 없음, `review=5` |
| 이번에 안 하는 것(사진·지도·PhotoRef 등)을 안 만들었다 | 예 | `git diff --stat`에 해당 파일 없음 |
| Done: `titles.json`이 착수 커밋과 바이트가 같다 | 예 | 착수 커밋 이후 수정 이력 없음 |
| Done: 커밋 이메일 `jongwoo315@gmail.com` | 예 | `git log -1 --format=%ae` |
| Done: PR 본문 맨 위 `## 착수 전 기준 (jw)` 절, Notion `PR` 속성 | 판정 불가 | 이 세션에서 PR 본문과 Notion을 확인하지 않았다 |

## 리뷰 한계

- `pr-review-toolkit:code-reviewer` 하위 에이전트는 끝나지 않아 중단했다. 일반 코드 리뷰는 리뷰 세션이 `Core/Sources`·`App` 전체를 직접 읽어 대신했고, 제목 해석 규칙(plan §제목 해석 규칙)과 어긋난 곳은 찾지 못했다
- 테스트·에러 처리 에이전트의 지적은 위 표에 반영했다. 코멘트·타입 설계·simplify 에이전트는 돌리지 않았다
- 앱 실행(설치·「가져오기」 탭)은 하지 않았다. 통과 기준 3의 설치·실행과 4는 jw가 확인한다
