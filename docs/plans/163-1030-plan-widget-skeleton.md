# #163 위젯 skeleton — App Group으로 저장 파일을 같이 쓰고 「오래 못 본 사람」 위젯을 띄운다

> **For Claude:** This plan is executed via /ralph-loop:ralph-loop in a detached orch session.
> You are ALREADY in the worktree, checked out on the feature branch. Do NOT switch branches,
> create another worktree, or use AskUserQuestion / any interactive prompt — the session is
> headless and cannot receive input, so always take the autonomous (recommended) default and
> keep working. Do NOT use superpowers:executing-plans or subagent-driven-development.
> Emit `<promise>RALPH_DONE</promise>` ONLY when every Done-criteria item and every Pre-PR check
> is genuinely true AND the PR has been created — never to escape the loop.
> Before emitting it, stop every background shell you started (TaskStop tool). A shell left
> running keeps the session in `bg` state, and orch never marks the step done.
> On a HARD, retry-proof API error (OpenAI insufficient_quota, 401/403, exhausted billing), STOP —
> do NOT emit RALPH_DONE, do NOT create a PR, do NOT spin retrying. It surfaces via the orch
> completion notification; a human fixes billing. (Transient TPM 429 is different — pace and retry.)
> A TRANSIENT error that stops being transient counts as HARD. If 429/529 keeps surfacing AND you
> have produced no commit and no file change for 20 minutes, STOP the same way. Waiting and
> spinning are indistinguishable in a headless loop — nobody is watching the screen, and the loop
> re-submits the prompt after every failed turn, so a server-side outage burns the whole iteration
> budget while the picker still reads `working`.

**Tier:** B — 새 target(위젯 확장)과 저장 위치 이동. 저장 위치가 바뀌면 기존 데이터가 안 보이지만 가져오기로 다시 만들 수 있다
**Notion:** #163 https://app.notion.com/p/40841e6165c0815cbf87d797e787f16a
**설계:** /Users/jw/prv/.wt/163-widget-skeleton/docs/plans/163-1030-design-widget-skeleton.md, 앱 설계 /Users/jw/prv/with-whom/docs/superpowers/specs/2026-10-28-with-whom-design.md
**흐름:** 이미 있다(#154 캘린더 → 해석 → 저장 → 앱 화면). 이 티켓은 같은 저장 파일에서 나가는 두 번째 출력(위젯)을 붙인다. 바꾸는 단계는 저장 위치(`WithWhomApp`의 `.modelContainer`)뿐이다

## jw 기준

오래 못 본 사람 작은 위젯이 생성된다

## 통과 기준

1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두)
2. `LongestUnseen.pick` 테스트가 아래 견본에서 기대한 사람·날 수를 돌려준다
3. 앱이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`). 빌드된 `WithWhom.app/PlugIns/`에 `WithWhomWidget.appex`가 들어 있다
4. 시뮬레이터에서 `-autoImport`로 실행한 뒤 저장 파일이 App Group 폴더에 생긴다(`xcrun simctl get_app_container <UDID> com.jongwoo315.withwhom groups`가 가리키는 폴더 아래 `Library/Application Support/default.store`)

## 실패 징후

1. **jw 기준을 재는 것.** 무인 루프는 jw 아이폰에 설치할 수 없다. PR 게이트에서 main 세션이 jw 아이폰에 설치한다. jw가 앱에서 가져오기를 한 번 누르고, 홈 화면 위젯 갤러리에서 「함께」의 작은 위젯을 추가한다. main은 App Group 폴더의 저장 파일을 복사해 「오래 못 본 사람」을 sqlite로 따로 계산하고, 위젯 화면(jw 스크린샷)과 맞춰 본다
   - 통과: 갤러리에 작은 위젯이 있고, 추가한 위젯에 저장 파일로 계산한 사람 이름과 날 수가 그대로 보인다
   - 다시 잰다: 위젯은 추가되지만 「아직 만난 사람이 없다」가 보이거나 이름·날 수가 계산과 다르다. 앱을 열어 가져오기를 다시 누른 뒤 한 번 더 본다. 그래도 다르면 미완
   - 미완: 갤러리에 위젯이 없거나, 추가해도 빈 칸·오류 화면이다
2. 저장 위치를 옮기면서 가져오기가 깨졌다. #155 게이트(2026-10-30) 실측은 일정 66개, 확인 필요 51개였다. 게이트에서 가져오기를 다시 누른 뒤 App Group 저장 파일의 `Moment` 수를 센다(그 사이 새 일정이 생겨 늘어나는 것은 정상)
   - 통과: 66개 이상
   - 다시 잰다: 60~65개. 빠진 일정을 본다
   - 미완: 59개 이하
3. `MEASURE` 줄 값이 main과 달라졌다. 이 티켓은 제목 해석을 건드리지 않는다

## 이번에 안 하는 것

- 나머지 위젯: 1년 전 오늘(#158·#159 뒤), 확인 필요 인터랙티브 버튼(#156 뒤), 이번 달. 잠금 화면 위젯
- 위젯을 눌렀을 때 그 사람 화면으로 바로 가기 — 기본 동작(앱 열기)만 둔다
- 옛 저장 파일 옮기기·지우기 — 새 위치는 빈 채로 시작하고 jw가 가져오기를 다시 누른다(설계 「정한 것」). 옛 파일은 그대로 둔다
- 실제 기기 검증 — 실패 징후 1·2는 PR 게이트에서 main이 잰다
- 저장 위치를 만들지 못할 때 옛 위치로 돌아가는 대체 경로 — 두지 않는다. 대체 경로가 있으면 기기에서 App Group이 깨져도 앱은 멀쩡해 보이고 위젯만 빈다. 만들지 못하면 지금처럼 `fatalError`로 바로 드러나게 둔다

## Task 1 — `LongestUnseen.pick` (Core, 순수 함수, TDD)

- 파일 `Core/Sources/WithWhomCore/LongestUnseen.swift`
- `LongestUnseen.pick(_ lastSeen: [(name: String, last: Date)], now: Date, calendar: Calendar) -> (name: String, days: Int)?`
  - `last`가 `now`보다 뒤인 항목은 무시한다(앞으로 잡힌 약속은 만난 것이 아니다)
  - 날 수는 `calendar`로 `last`의 날짜와 `now`의 날짜 사이 달력 날짜 차이(`startOfDay` 기준)
  - 날 수가 가장 큰 사람. 같으면 이름 오름차순 첫 번째
  - 남는 항목이 없으면 `nil`
- 테스트 견본 (`Calendar(identifier: .gregorian)`, timeZone `Asia/Seoul`, now = 2026-10-30 09:00)

| 입력 | 기대 |
| --- | --- |
| 빈 목록 | `nil` |
| 가람 10-20 12:00, 나래 10-01 18:00 | 나래, 29 |
| 가람 10-29 23:30 하나 | 가람, 1 (24시간이 안 지났어도 날짜가 하루 다르다) |
| 가람 11-05(미래) 하나 | `nil` |
| 가람 10-01, 다솜 10-01 | 가람, 29 |

## Task 2 — 저장 파일을 App Group으로 옮긴다 (App)

- `App/Models.swift` 끝에 앱과 위젯이 같이 쓰는 컨테이너 함수를 둔다

```swift
enum SharedStore {
    static let groupId = "group.com.jongwoo315.withwhom"
    static func makeContainer() throws -> ModelContainer {
        try ModelContainer(for: Moment.self, Person.self,
                           configurations: ModelConfiguration(groupContainer: .identifier(groupId)))
    }
}
```

- `WithWhomApp`: `.modelContainer(for:)` 대신 `SharedStore.makeContainer()`로 만든 컨테이너를 넘긴다. 실패하면 `fatalError`(위 「이번에 안 하는 것」 마지막 줄)
- `App/WithWhom.entitlements`에 `com.apple.security.application-groups` = `[group.com.jongwoo315.withwhom]`. `project.yml`의 앱 target `entitlements:`로 지정한다
- `project.yml` 앱 target에 `attributes: SystemCapabilities: com.apple.ApplicationGroups.iOS: enabled: 1`도 넣는다(Xcode 화면에서 그룹이 켜진 것으로 보이게)
- `Importer.run`이 저장을 마친 뒤 `WidgetCenter.shared.reloadAllTimelines()`를 부른다

## Task 3 — 위젯 확장 target (App + Widget)

- `project.yml`에 target `WithWhomWidget` (type `app-extension`, platform iOS, bundle id `com.jongwoo315.withwhom.widget`)
  - sources: `Widget/`, `App/Models.swift`, `Core/Sources/WithWhomCore`
  - info: `NSExtension` → `NSExtensionPointIdentifier` = `com.apple.widgetkit-extension`, `CFBundleDisplayName` = `함께`
  - entitlements: `Widget/WithWhomWidget.entitlements`, 같은 App Group. `SystemCapabilities`도 앱과 같이
  - 앱 target `dependencies`에 `- target: WithWhomWidget` (embed)
- `Widget/WithWhomWidget.swift`
  - `@main struct WithWhomWidgetBundle: WidgetBundle` 안에 위젯 하나, `supportedFamilies([.systemSmall])`, 이름 「오래 못 본 사람」
  - `TimelineProvider`: `SharedStore.makeContainer()`로 `ModelContext`를 만들어 `Person`을 모두 읽고, 사람마다 지금 이전에 시작한 `Moment` 중 가장 늦은 `start`를 모아 `LongestUnseen.pick`에 넘긴다. 컨테이너를 못 만들면 빈 상태 엔트리
  - 엔트리 하나, 다음 갱신은 다음 날 0시(`.after`)
  - 화면: 이름(크게), 「N일째 못 봄」. 결과가 `nil`이면 「아직 만난 사람이 없다」. `containerBackground(.fill.tertiary, for: .widget)`
  - `placeholder`와 `getSnapshot`은 가명 견본(「가람」, 12일)

## Task 4 — 마무리

- `README.md`: 위젯 한 줄, 저장 위치가 App Group으로 바뀌었고 처음에는 가져오기를 다시 눌러야 한다는 것, 실기기 첫 설치 때 Xcode Signing & Capabilities에서 두 target 모두 App Group을 한 번 등록해야 할 수 있다는 것(무료 계정은 명령줄 빌드만으로 그룹이 등록되지 않았다, 2026-10-30)
- Pre-PR checks → 커밋 → PR

## Pre-PR checks

> Pre-PR checks (all required — do not assume pass, show output):
> 1. New env vars: `git diff main...HEAD` added lines matching `os\.environ\.get|os\.getenv|process\.env\.` — log any found.
> 2. Server boots — detached-safe, NO interactive Ctrl+C (no TTY in orch). Background + timeout + curl the port + kill. Never bare `runserver` (hangs the loop till ORCH_STUCK_SECS). Django → `source <venv>/bin/activate && cd web && (timeout 20 python manage.py runserver 127.0.0.1:8000 --noreload &) ; sleep 8; curl -sf http://127.0.0.1:8000/ -o /dev/null && echo BOOT_OK ; pkill -f runserver`; CDK → `cdk synth` (no server); Zappa/Lambda Django → same background+timeout with `PYENV_VERSION=<env> --settings=<app>.settings.local`; CLI/library → smoke-run the entrypoint (it must self-terminate); else project-specific.
> 3. Full test suite green (show pass/fail). If no runner: state `no tests — skipped`, do not silently pass.
> Then: completeness via `sc:reflect` vs plan; code review via `superpowers:requesting-code-review` (fix all Critical/Important); commit (`~/prv` repo면 `docs/plans/`도 포함. `~/plab`·`~/work` repo는 `docs/plans/`를 커밋하지 않는다 — `rules/github.md` §회사 repo에 커밋하지 않는 것); PR via `gh pr create --assignee @me` (work title `[DEV-XXXX] type: 설명` + Summary/Changes/Test Plan/Jira; personal title + Summary/Changes/Notes, then update the Notion PR property). **PR을 만들면 이 루프는 끝난다** — 여기서 `pr-review-toolkit:review-pr`을 돌리지 말 것. 그 리뷰는 Phase C의 별도 세션이 맡는다. 여기서 돌리면 (a) 자기가 쓴 코드를 같은 컨텍스트가 리뷰하고 (b) PR 생성 후에도 커밋이 계속 얹혀 `orch ls`의 `done`이 완료를 뜻하지 않게 된다 (실측: PR 후 8분 이상 지속).
>
> 내장 `/code-review`를 여기 쓰지 말 것. 품질은 더 낫지만(다각도 finder + 후보별 독립 검증 CONFIRMED/PLAUSIBLE/REFUTED + failure_scenario 강제) **사람이 직접 치는 커맨드라 available-skills에 없다** — 헤드리스 세션에서 확인함. ralph가 호출하면 없는 스킬을 찾다 끝난다.
>
> 커밋 전 `superpowers:requesting-code-review`는 그대로 둔다 — 그건 커밋하기 전 자기 점검이고, Phase C는 커밋된 diff 전체를 새 컨텍스트가 다시 보는 것이라 겹치지 않는다.

이 repo에서의 구체 명령:

1. env: Swift라 위 패턴은 해당 없다. 대신 `git diff main...HEAD | grep -E '^\+.*ProcessInfo\.processInfo\.environment'`를 돌려 결과를 적는다
2. 앱 실행 확인 (서버 대신). README에 적힌 `-target -sdk` 방식으로 빌드한다. 시뮬레이터는 끝나면 반드시 끈다
   ```bash
   xcodegen generate
   xcodebuild -project WithWhom.xcodeproj -target WithWhom -sdk iphonesimulator -configuration Debug build | tail -3
   APP=build/Debug-iphonesimulator/WithWhom.app
   ls "$APP/PlugIns/WithWhomWidget.appex" && plutil -extract NSExtension.NSExtensionPointIdentifier raw "$APP/PlugIns/WithWhomWidget.appex/Info.plist"
   UDID=$(xcrun simctl list devices available | grep 'iPhone 17 Pro (' | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
   xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl install "$UDID" "$APP"
   xcrun simctl launch "$UDID" com.jongwoo315.withwhom -autoImport && sleep 5 && xcrun simctl spawn "$UDID" launchctl list | grep -q withwhom && echo BOOT_OK
   G=$(xcrun simctl get_app_container "$UDID" com.jongwoo315.withwhom groups | grep withwhom | awk '{print $2}')
   ls -la "$G/Library/Application Support/" | grep default.store
   xcrun simctl shutdown "$UDID"
   ```
   빌드 경로가 다르면 `xcodebuild -showBuildSettings`의 `BUILT_PRODUCTS_DIR`을 쓴다. 시뮬레이터 권한 창 때문에 `-autoImport`가 일정 0개를 가져오는 것은 정상이다. 저장 파일이 App Group 폴더에 생기는지만 본다
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 main과 같아야 한다

## Done criteria

- 통과 기준 1~4가 사실이고, 위 Pre-PR 2번 출력(appex 경로, `com.apple.widgetkit-extension`, `BOOT_OK`, App Group 폴더의 `default.store`)을 PR 본문에 붙인다
- `Core/Tests/WithWhomCoreTests/Resources/titles.json`을 고치지 않는다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문 + 「기기 측정은 PR 게이트에서 main이 한다(실패 징후 1·2)」 + 루프가 잰 것(`LongestUnseen` 테스트 결과, `MEASURE` 두 줄, 시뮬레이터 확인 출력)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`docs:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #163의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40841e61-65c0-815c-bf87-d797e787f16a /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
