# #155 리뷰 — PR #2

**대상:** `main...HEAD` — 7 commits(이 리뷰의 fix 2개 포함, 리뷰 파일 제외), 12 files, +442 −11
**plan:** docs/plans/155-1029-plan-skip-holidays.md

## 지적

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `App/CalendarSource.swift:13` | 스위치를 한 번 바꾸면 그날의 뺀 목록이 그대로 저장되어, 이후 새로 구독한 휴일 캘린더나 id가 바뀐 휴일 캘린더에는 기본값 규칙이 다시 적용되지 않고 공휴일이 들어온다. jw 기준과 어긋난다 | fix `38e34a2` |
| 2 | Important | `App/Importer.swift:57` | 이미 들어온 일정을 지우는 동작이 Core 밖 반복문 안에 있어 테스트가 없다. plan Done criteria가 Core 테스트나 나눈 함수 테스트로 보이라고 했다 | fix `431f657` |
| 3 | Important | `App/Importer.swift:57` | 지우기는 이번에 읽은 기간(1년 전 ~ 30일 뒤)의 일정 id만 대상이라, 기간 밖으로 밀려난 옛 공휴일 `Moment`는 캘린더를 꺼도 남는다. 통과 기준 4의 「이미 들어와 있던 것은 지워진다」가 기간 안에서만 참이다 | defer — 고치려면 `Moment`에 `calendarId`를 저장하는 스키마 변경과 기존 데이터 이전이 필요해 이 리뷰의 범위(지적 하나를 고치는 것)를 넘는다. README에 한계를 적었다(`38e34a2`). 후속 티켓에서 `Moment.calendarId`를 넣고 꺼진 캘린더 기준으로 지운다 |
| 4 | Suggestion | `App/ContentView.swift:16` | 시트를 닫을 때 시작하는 가져오기가 이미 도는 가져오기와 겹치면 첫 실행이 끝나는 순간 `isRunning`이 false가 되고 `message`가 뒤섞인다. 에이전트 3곳이 지적했다 | push-back — 데이터는 어긋나지 않는다. `upsert`에 `await`가 없어 `@MainActor`에서 순서대로 실행되고, 각 실행이 저장 직전에 뺀 목록을 읽는다. `isRunning`을 보고 건너뛰면 시트에서 바꾼 선택을 적용하는 재실행이 빠질 수 있어 그쪽이 더 나쁘다. 버튼 상태와 메시지 순서만 흔들린다 |
| 5 | Suggestion | `Core/Sources/WithWhomCore/CalendarFilter.swift:25` | 이름에 「휴일」·「holiday」가 든 일반 캘린더(예: 「주말·휴일 약속」)도 기본값에서 빠지고 이미 들어온 일정이 지워진다. 구독 캘린더는 사람 이름이 든 일정이 있어도 기본값에서 전부 빠진다 | 기록만 — plan Task 1이 정한 기본값 규칙이다. 화면에서 켤 수 있고 README에 적었다(`38e34a2`) |
| 6 | Suggestion | `Core/Sources/WithWhomCore/MomentBuilder.swift:11` | `calendarId` 기본값이 `""`라 인자를 빼먹은 호출이 컴파일되고 거르기를 우회한다. 지금 쓰는 호출은 `CalendarSource.swift`의 한 곳이고 그곳은 넘긴다 | 기록만 — 기존 테스트 호출부를 안 바꾸려고 plan Task 1이 기본값을 정했다 |
| 7 | Suggestion | `App/CalendarSource.swift:14` | `stringArray`가 nil이면(값이 깨졌을 때) 저장한 적 없는 것과 같게 처리해 선택이 조용히 기본값으로 돌아간다 | 기록만 |
| 8 | Suggestion | `App/Importer.swift:46` | 저장 실패를 화면 문구로만 알리고 로그가 없어 fetch·삭제·저장 중 어디서 실패했는지 남지 않는다 | 기록만 |
| 9 | Suggestion | `App/Importer.swift:14` | 설명 주석의 순서(일정 → 반복 제외 → 제목 해석 → 저장)에 뺀 캘린더 거르기가 빠졌다. 끝 메시지의 뺀 개수는 고유 id 수라 반복 일정 id도 센다 | 기록만 |
| 10 | Suggestion | `App/CalendarPickerView.swift:33` | 불러오는 동안 안내가 없다. `CalendarSource.swift`의 `event.calendar`는 암시적 언래핑이고, id 없는 일정은 개수 없이 건너뛴다(이번 PR 이전부터 있던 동작) | 기록만 |
| 11 | Suggestion | `Core/Sources/WithWhomCore/CalendarFilter.swift:32` | 캘린더를 끈 뒤 몇 달 지나 다시 켜면 그 사이 기간 밖으로 밀린 일정은 다시 안 들어온다(#3의 반대쪽) | 기록만 — 일정 원본은 캘린더에 남아 있다. #156이 편집을 넣으면 다시 본다 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다 | 예 | `swift test` 34 tests passed(fix 커밋 뒤). `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1`, `MEASURE shape=split auto_ok=25/25 review=5 wrong=1` |
| `CalendarFilter`의 기본값 테스트가 캘린더 견본에서 정확히 공휴일·생일 캘린더만 뺀다 | 예 | `Core/Tests/WithWhomCoreTests/CalendarFilterTests.swift` `defaultExcluded`, 견본 7개 |
| 앱이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`) | 빌드 예 / 실행 판정 불가 | `xcodebuild -target WithWhom -sdk iphonesimulator` `BUILD SUCCEEDED`(fix 커밋 뒤). 리뷰 세션에서 시뮬레이터를 실행하지 않았다 |
| 툴바 「캘린더」 버튼으로 목록 화면이 열리고 스위치가 있다. 끈 캘린더 일정은 다음 가져오기에서 안 들어오고 이미 들어온 것은 지워진다 | 일부 예 | 버튼 `App/ContentView.swift:40`, 스위치 `App/CalendarPickerView.swift:22`. 안 들어옴 `splitEvents`·`sharedIdIsNotDropped`, 지움 판단 `staleSourceIds`·`nothingExcluded`(`431f657`) 테스트 통과. 지우기는 읽은 기간 안의 일정만 대상이다(지적 3). 화면이 실제로 열리는지는 확인하지 않았다 |
| `titles.json`을 고치지 않는다 | 예 | `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json` 비어 있음 |
| 실패 징후 1·2(기기 측정) | 판정 불가 | PR 게이트에서 main이 jw 아이폰으로 잰다 |

## 확인한 것

- 환경변수: `git diff main...HEAD | grep -E '^\+.*ProcessInfo\.processInfo\.environment'` 결과 없음
- 테스트는 fix 커밋 뒤에 다시 돌렸다. 시뮬레이터 실행(`BOOT_OK`)은 이 세션에서 하지 않았다
