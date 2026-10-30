# 163 리뷰 — PR #3

**대상:** `main...HEAD` — 10 commits (구현 6 + 리뷰 fix 4), 15 files, +656 −1 (리뷰 파일 제외)
**plan:** docs/plans/163-1030-plan-widget-skeleton.md

## 지적

| # | 심각도 | 위치 | 내용 | 처리 |
| --- | --- | --- | --- | --- |
| 1 | Important | `Widget/WithWhomWidget.swift:33,37` | 위젯이 컨테이너를 못 만들거나 읽지 못해도 `try?`가 nil을 돌려줘 빈 저장 파일과 같은 「아직 만난 사람이 없다」가 뜨고, 다음 갱신도 다음 날 0시라 일시적 실패(재부팅 직후 잠금 상태, 가져오기 중 저장 파일 사용 중)가 자정까지 남는다 | defer — plan Task 3이 「컨테이너를 못 만들면 빈 상태 엔트리」로 정했고 PR 본문 Notes에도 적혀 있다. 읽기 실패와 빈 저장 파일의 구분은 PR 게이트에서 App Group 저장 파일을 sqlite로 따로 계산해 맞춰 보는 것으로 하기로 했다. 실패 상태 화면·짧은 재시도(`.after(now+15분)`)·`os.Logger`는 표시 문구와 갱신 정책을 바꾸는 plan 변경이라 후속 티켓에서 정한다. 데이터를 쓰거나 지우는 일은 없다 |
| 2 | Important | `Core/Tests/WithWhomCoreTests/LongestUnseenTests.swift:27` | 여러 명 테스트가 모두 가장 오래된 사람을 입력 마지막에 둬서, `pick`을 `.last`로 바꿔도 통과한다 | fix `0d7520d` |
| 3 | Important | `Core/Tests/WithWhomCoreTests/LongestUnseenTests.swift:52` | 동률 테스트가 같은 `Date` 두 개만 써서, 날짜 대신 시각을 비교하도록 바뀌어도 통과한다 | fix `50b6e21` |
| 4 | Important | `Core/Sources/WithWhomCore/LongestUnseen.swift:9` | `last == now`와 오늘 이른 시각(0일)이 테스트에 없어서 `<=`를 `<`로 바꿔도 통과한다 | fix `c147ab9` |
| 5 | Important | `Core/Tests/WithWhomCoreTests/LongestUnseenTests.swift:5` | `Asia/Seoul`만 써서 넘겨받은 `calendar`를 무시하거나 `timeIntervalSince / 86400`으로 바꿔도(서머타임 날 하루가 어긋난다) 통과한다 | fix `c47b34f` |
| 6 | Suggestion | `WithWhom.xcodeproj/project.pbxproj:186,189` | `SystemCapabilities`가 dictionary가 아니라 문자열로 생성돼(`project.yml:28-31,55-58`) 「Xcode 화면에서 그룹이 켜진 것으로 보이게」라는 목적이 이뤄지지 않는다. 실제 권한은 entitlements 파일에서 와서 빌드·서명은 영향이 없다 | 기록만 |
| 7 | Suggestion | `Widget/WithWhomWidget.swift:27` | 갱신이 다음 날 0시와 가져오기 뒤뿐이라, 09:00에 미래였던 오늘 14:00 일정은 만난 뒤에도 자정까지 반영되지 않는다. plan Task 3 그대로다 | 기록만 |
| 8 | Suggestion | `App/WithWhomApp.swift:9` | 주석과 plan이 `groupContainer` 구성이 그룹을 못 쓸 때 throw한다고 가정한다. 이 세션은 확인하지 못했다. throw 대신 앱 샌드박스에 조용히 저장 파일을 만들면 앱·위젯 모두 `fatalError` 없이 서로 다른 빈 저장 파일을 본다. 통과 기준 4(App Group 폴더에 `default.store`)가 앱 쪽만 잰다 | 기록만 |
| 9 | Suggestion | `Widget/WithWhomWidget.swift:27,31,34` | 주석이 근거 없이 단정한다: `.after`는 요청일 뿐 시각을 보장하지 않고(대체값은 24시간 뒤), `context는 container를 붙잡지 않으므로`는 SwiftData 내부 동작을 출처 없이 적었다 | 기록만 |
| 10 | Suggestion | `README.md:16,27` | 「이 티켓에서 저장 위치가 바뀌었다」는 시간이 지나면 가리키는 곳이 사라진다(날짜 필요). 27행의 「앱 target은 Core를 직접 컴파일한다」는 위젯 target도 같이 컴파일하게 되어 불완전하다 | 기록만 |
| 11 | Suggestion | `App/Models.swift:37` | App Group id 문자열이 Swift 상수 1곳, entitlements 2곳, `project.yml` 2곳에 손으로 맞춰져 있어 오타가 나면 실행할 때야 드러난다 | 기록만 |
| 12 | Suggestion | `Widget/WithWhomWidget.swift:11,39` | `(name: String, days: Int)?`가 네 군데 반복되고 `UnseenEntry`가 `Equatable`이 못 된다. `last <= now` 필터가 `load`와 `pick`에 이중으로 있다. 필드가 늘 때 `struct`로 바꾸면 된다 | 기록만 |
| 13 | Suggestion | `Widget/WithWhomWidget.swift:32-44` | `load`의 사람→(이름, 마지막 시각) 변환이 단위 테스트 밖에 있다. `ModelConfiguration(isStoredInMemoryOnly:)`로 잴 수 있다 | 기록만 |

## plan 대조

| plan 기준 | 코드가 만족하나 | 증거 |
| --- | --- | --- |
| 통과 기준 1: `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두) | 예 | fix 4건 반영 뒤 `swift test` 45개 통과. `MEASURE shape=fullInGiven auto_ok=25/25 review=5 wrong=1`, `MEASURE shape=split auto_ok=25/25 review=5 wrong=1` |
| 통과 기준 2: `LongestUnseen.pick` 테스트가 견본에서 기대한 사람·날 수를 돌려준다 | 예 | `Core/Tests/WithWhomCoreTests/LongestUnseenTests.swift` 견본 5행 모두 있음 + 추가 테스트 5개 |
| 통과 기준 3: iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`). `PlugIns/`에 `WithWhomWidget.appex`가 있다 | 빌드·appex는 예. `BOOT_OK`는 판정 불가 | 이 세션에서 `xcodebuild -target WithWhom -sdk iphonesimulator`가 `** BUILD SUCCEEDED **`, `build/Debug-iphonesimulator/WithWhom.app/PlugIns/WithWhomWidget.appex` 있음, 확장 지점 `com.apple.widgetkit-extension`. `BOOT_OK`는 PR 본문 주장이고 이 세션은 시뮬레이터를 실행하지 않았다 |
| 통과 기준 4: `-autoImport` 실행 뒤 저장 파일이 App Group 폴더 `Library/Application Support/default.store`에 생긴다 | 판정 불가 | PR 본문 주장(`default.store / -shm / -wal`). 이 세션은 실행하지 않았다. 위젯 프로세스가 같은 폴더를 여는지는 기기에서만 잰다(지적 8) |
| 실패 징후 3: `MEASURE` 줄 값이 main과 달라지지 않는다 | 예 | 위 통과 기준 1과 같은 출력. `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다(0줄) |
| 실패 징후 1·2: 기기 위젯 표시, 가져오기 뒤 `Moment` 66개 이상 | 판정 불가 | plan이 PR 게이트에서 main이 측정하기로 정한 항목 |
| 이번에 안 하는 것: 나머지 위젯, 딥링크, 옛 저장 파일 이동, 대체 경로 | 예(범위 밖 작업 없음) | `git diff --stat main...HEAD`에 해당 파일 없음. 앱 쪽 `fatalError`만 있고 옛 위치로 돌아가는 코드가 없다 |
| Done criteria: Pre-PR env 점검(`ProcessInfo.processInfo.environment` 추가 줄 없음) | 예 | `git diff main...HEAD \| grep -E '^\+.*ProcessInfo\.processInfo\.environment'` 0건 |

## 확인한 것

- `xcodegen generate` 뒤 `git status`가 깨끗하다: `project.yml`과 커밋된 `project.pbxproj`가 같다
- `LongestUnseen.pick` 비교식은 날 수가 큰 쪽, 같으면 이름 오름차순 첫 번째다
- `Importer.swift:51`의 `reloadAllTimelines()`는 `save()`가 성공한 뒤에만 불린다. 앱에서 데이터를 바꾸는 곳은 `Importer` 하나다
- 위젯 target이 같이 컴파일하는 `Models.swift`와 Core 소스에 앱 전용 API가 없다

테스트는 fix 뒤 `cd Core && swift test`로 45개 모두 통과했다. 시뮬레이터 실행(`BOOT_OK`)과 기기 위젯은 이 세션에서 돌리지 않았다.
