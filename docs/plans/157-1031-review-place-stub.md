# 157 리뷰 — PR #5

**대상:** `main...HEAD` — 5 commits, 11 files, +267 −7
**plan:** docs/plans/157-1031-plan-place-stub.md

## 지적

고친 것은 없다. Critical은 0건이고 Important 둘은 지금 장소 값이 나오는 경로가 없어 아직 일어나지 않는 일이라 #159로 미뤘다.

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `App/Importer.swift:144` | 이미 있는 일정은 `draft.place`가 `nil`이 아닐 때만 장소를 덮어쓴다는 규칙을 확인하는 자동 테스트가 없다. `if let`을 무조건 대입으로 바꿔도 `swift test`와 시뮬레이터 확인이 둘 다 통과한다(장소 값이 `NULL`뿐이라서). App target에는 테스트 target이 없고 `upsert`는 `ModelContext`에 기대 `Core/`의 `swift test`로 닿지 않는다 | defer — 장소 값이 처음 나오는 #159에서 규칙이 실제로 걸린다. 지금 병합 함수를 Core로 빼면 아래 2번의 이름 덮어쓰기 규칙을 #159보다 먼저 정하게 된다. #159 plan에 이 테스트를 넣는다 |
| 2 | Important | `App/Importer.swift:167` | `apply`가 `place.name`을 무조건 대입한다. 역지오코딩에 실패해 이름 없이 좌표만 가진 `Place`로 다시 가져오면 저장된 `placeName`이 `nil`로 바뀐다. plan이 말한 「저장된 장소를 지우지 않는다」는 `place`가 `nil`일 때만 지킨다 | defer — 좌표가 달라진 새 `Place`에 옛 이름을 남기면 오히려 틀린 이름이 붙는다. 이름을 어떻게 합칠지는 장소를 만드는 #159가 정한다. 지금은 `draft.place`가 언제나 `nil`이라 이 줄이 실행되지 않는다 |
| 3 | Suggestion | `App/Models.swift:14` | `Moment`가 위도만 있고 경도가 없는 상태, 이름만 있고 좌표가 없는 상태를 담을 수 있다. 지금은 `apply`가 셋을 함께 쓰므로 만들어지지 않는다. `PlacesView`는 그런 행을 조용히 숨기고 `MomentRow`는 이름을 보여 준다 | 기록만 |
| 4 | Suggestion | `App/PlacesView.swift:10` | 「위도·경도가 둘 다 있다」 검사가 `filter`와 `if let`에 두 번 나온다. `NaN`이나 범위 밖 값도 막지 않는다 | 기록만 |
| 5 | Suggestion | `Core/Sources/WithWhomCore/MomentBuilder.swift:22` | `Place.init`이 위도 ±90, 경도 ±180 범위 밖 값과 `NaN`을 받는다. 값을 만드는 곳이 아직 없어 지금은 걸러 줄 대상이 없다 | 기록만 — #159에서 값을 만들 때 정한다 |
| 6 | Suggestion | `Core/Tests/WithWhomCoreTests/MomentBuilderTests.swift:57` | `placeWithoutName`은 구조체 초기화와 `==`만 확인해 회귀를 잡는 힘이 거의 없다 | 기록만 |
| 7 | Suggestion | `App/Importer.swift:132` | 캘린더를 끄면 그 일정의 `Moment`가 지워지고, 다시 켜도 캘린더에서 온 `draft.place`는 `nil`이라 사진으로 채운 장소가 돌아오지 않는다. 지금은 장소 값이 없어 피해가 없다 | 기록만 — #159 plan에 사진 좌표를 다시 계산할 수 있는지 한 줄 적는다 |
| 8 | Suggestion | `docs/plans/157-1031-plan-place-stub.md:76` | 시뮬레이터 마이그레이션 확인은 캘린더 권한이 없어 일정 0개인 저장 파일로 했다. `PRAGMA` 출력은 열이 생겼다는 것만 보여 주고 기존 행이 남는지는 재지 못했다 | 기록만 — plan 실패 징후 1 (다)의 PR 게이트 아이폰 측정(일정 66, 별칭 6)이 그 근거다 |
| 9 | Suggestion | `App/ContentView.swift:12` | 주석 「탭 탭 없이」가 모호하다. `-openTab` 값이 `people`·`dates`·`review`·`places` 중 하나여야 한다는 말도 없다. 다른 값이면 탭이 선택되지 않는다 | 기록만 |
| 10 | Suggestion | `App/Importer.swift:142` | 주석과 README `## 장소별` 셋째 줄이 「장소를 모르는 가져오기는 저장된 장소를 지우지 않는다」고만 쓴다. `place`가 `nil`일 때만 참이라는 한정이 없다(위 2번) | 기록만 |
| 11 | Suggestion | `Core/Sources/WithWhomCore/MomentBuilder.swift:21` | 주석이 아직 없는 역지오코딩을 사실처럼 쓴다. `// stub: #159` 주석(69번째 줄)도 #159가 병합되면 지워야 한다 | 기록만 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| 1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두) | 예 | 이 세션에서 `cd Core && swift test` 실행: `Test run with 64 tests in 6 suites passed`. `MEASURE shape=split auto_ok=25/25 review=5 wrong=1`, `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1`. main과 같은지는 PR 본문 주장(main 쪽은 이 세션에서 다시 재지 않음) |
| 2. `MomentBuilder.build`가 만든 초안은 모두 `place == nil`이다(테스트) | 예 | `Core/Tests/WithWhomCoreTests/MomentBuilderTests.swift:50-55` `draftsHaveNoPlace` 통과. `build`가 `place: nil`을 넣는 곳은 `Core/Sources/WithWhomCore/MomentBuilder.swift:69` |
| 3. 앱과 위젯이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`). main 빌드로 먼저 설치해 저장 파일을 만든 뒤 이 브랜치를 덮어 설치해도 뜬다 | 판정 불가 | 위젯 파일 `build/Debug-iphonesimulator/WithWhom.app/PlugIns/WithWhomWidget.appex/WithWhomWidget`가 있다. `BOOT_OK`와 덮어 설치는 PR 본문 출력만 있고 이 세션은 앱을 다시 빌드하거나 실행하지 않았다 |
| 4. 시뮬레이터 저장 파일의 `ZMOMENT`에 `ZPLACENAME`·`ZLATITUDE`·`ZLONGITUDE` 열이 있다 | 예 | PR 본문에 붙은 `PRAGMA table_info(ZMOMENT)` 출력 10~12번 열(이 세션은 저장 파일을 다시 열지 않았다). 코드는 `App/Models.swift:14-16`에 옵셔널 셋을 더했다 |
| 5. 탭이 넷이고 넷째 「장소별」이 지도를 띄운다. 좌표가 있는 일정이 0개라 「아직 장소가 있는 일정이 없다」가 보인다(시뮬레이터 스크린샷) | 예 | `App/ContentView.swift:21-24`가 탭 넷을 만든다. 스크린샷 `/private/tmp/claude-501/-Users-jw-prv--wt-157-place-stub/48fd9d44-d83a-4b39-8b65-c091b5655277/scratchpad/places.png`에 네 탭, 지도, 「아직 장소가 있는 일정이 없다」가 보인다 |
| Done: `titles.json`을 고치지 않는다 | 예 | `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다 |
| 실패 징후 2: 장소 값이 생기지 않는다 | 판정 불가 | 값을 만드는 코드가 없다(`build`가 `nil`만 넣는다). 저장 파일에서 `NULL`이 아닌 일정 수는 이 세션이 세지 않았다. PR 본문은 0개라고 적었다 |

## 확인한 것

- 이 세션은 `Core/`에서 `swift test`만 다시 돌렸다. 앱·위젯 빌드와 시뮬레이터 실행은 하지 않았다
- 수정 커밋이 없어 `git push`할 코드 변경이 없다
