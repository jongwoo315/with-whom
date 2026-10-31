# #157 Moment에 장소 이름·좌표 칸과 빈 지도 탭을 stub으로 넣는다

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

**Tier:** B — 저장 모델에 옵셔널 칸 셋을 더하고(자동 마이그레이션) 탭 하나를 더한다. 값을 만드는 로직은 없다
**Notion:** #157 https://app.notion.com/p/40841e6165c081c8b6eaea3dacdf969f
**설계:** /Users/jw/prv/.wt/157-place-stub/docs/plans/157-1031-design-place-stub.md, 앱 설계 /Users/jw/prv/with-whom/docs/superpowers/specs/2026-10-28-with-whom-design.md §1·§3
**흐름:** 이미 있다(캘린더 → 제목 해석 → 저장 → 앱 화면·위젯). 이 티켓은 그 흐름에 장소 stub을 끼운다 — `MomentBuilder.build`가 장소를 언제나 `nil`로 채우고, 저장과 화면이 그 값을 나른다. 장소가 비어 있는 것이 정상이다. 값을 채우려고 장소를 지어내지 말 것(#159가 사진 좌표로 바꾼다)

## jw 기준

제목이 통과 기준

(가리키는 제목: 「Moment에 장소 이름·좌표 칸과 빈 지도 탭을 stub으로 넣는다」)

## 통과 기준

1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두)
2. `MomentBuilder.build`가 만든 초안은 모두 `place == nil`이다(테스트)
3. 앱과 위젯이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`). **main 빌드로 먼저 설치해 저장 파일을 만든 뒤** 이 브랜치를 덮어 설치해도 뜬다
4. 시뮬레이터 저장 파일의 `ZMOMENT`에 `ZPLACENAME`·`ZLATITUDE`·`ZLONGITUDE` 열이 있다
5. 탭이 넷이고 넷째 「장소별」이 지도를 띄운다. 좌표가 있는 일정이 0개라 「아직 장소가 있는 일정이 없다」가 보인다(시뮬레이터 스크린샷)

## 실패 징후

1. **jw 기준을 재는 것.** 세 가지를 센다
   - (가) 저장 파일 `ZMOMENT`의 장소 열: 3개(`ZPLACENAME`·`ZLATITUDE`·`ZLONGITUDE`)면 통과, 1~2개면 다시 잰다(열 이름이 바뀌었는지 `PRAGMA table_info`로 본다), 0개면 미완
   - (나) 「장소별」 탭: 지도와 빈 상태 문구가 보이면 통과, 탭은 있는데 지도나 문구가 안 보이면 다시 잰다(스크린샷을 다시 찍는다), 탭이 없거나 앱이 죽으면 미완
   - (다) 기존 저장 파일이 그대로 열린다. PR 게이트에서 main이 jw 아이폰에 설치하기 전·후로 App Group 저장 파일을 복사해 일정 수와 별칭 수를 센다(#156 게이트 뒤 값: 일정 66, 별칭 6)
     - 통과: 둘 다 같다
     - 다시 잰다: 늘었다(설치 뒤 가져오기가 같이 돌았는지 보고, 가져오기 전 복사본으로 다시 센다)
     - 미완: 하나라도 줄었거나 앱이 열리지 않는다
     - 아이폰을 연결할 수 없으면 (다)는 판정 불가로 적는다
2. 장소 값이 생겼다. 시뮬레이터·기기 저장 파일에서 `ZPLACENAME`·`ZLATITUDE`·`ZLONGITUDE`가 하나라도 `NULL`이 아닌 일정 수
   - 통과: 0개
   - 다시 잰다: 없음(stub이라 값이 나올 경로가 없다)
   - 미완: 1개 이상(어디선가 장소를 지어냈다)
3. `MEASURE` 줄 값이 main과 달라졌다
4. 위젯 target 빌드가 깨졌다(`App/Models.swift`를 같이 컴파일한다)

## 이번에 안 하는 것

- 사진 읽기(#158), 좌표 묶기·역지오코딩(#159), 집 고르기(#160), Takeout(#161)
- 장소를 따로 `Place` 모델로 두기 — 같은 장소를 여러 일정이 공유하는 것은 #159가 정한다
- 앱 설계 §1의 `출처` 칸 — 출처가 캘린더 하나뿐이라 지금은 쓸 데가 없다
- 위치 권한 — 지도는 사용자 위치를 쓰지 않는다
- 지도 표시를 눌렀을 때의 상세 화면

## Task 1 — 장소 stub (Core, TDD)

- `public struct Place: Sendable, Equatable { public var name: String?; public var latitude: Double; public var longitude: Double }` (public init 포함)
- `MomentDraft`에 `public var place: Place?`. `MomentBuilder.build`는 `place: nil`을 넣는다. 그 자리에 `// stub: #159가 사진 좌표 묶음으로 바꾼다` 주석 한 줄
- 테스트: 기존 `MomentBuilderTests` 입력으로 만든 초안이 모두 `place == nil`
- `MEASURE` 두 줄이 그대로인지 같이 본다

## Task 2 — 저장 칸과 가져오기 (App)

- `App/Models.swift`의 `Moment`에 `var placeName: String? = nil`, `var latitude: Double? = nil`, `var longitude: Double? = nil`. `init` 시그니처는 바꾸지 않는다
- `Importer.upsert`: 새 `Moment`에는 `draft.place`를 옮긴다. 이미 있는 `Moment`는 `draft.place`가 `nil`이 아닐 때만 덮어쓴다(장소를 모르는 가져오기가 저장된 장소를 지우지 않게)
- 마이그레이션 확인(시뮬레이터): `main`을 빌드해 설치 → `-autoImport`로 한 번 실행 → 이 브랜치를 빌드해 **uninstall 없이** 덮어 설치 → 실행. App Group 저장 파일(`xcrun simctl get_app_container "$UDID" com.jongwoo315.withwhom group.com.jongwoo315.withwhom`)의 `Library/Application Support/default.store`에서 `PRAGMA table_info(ZMOMENT)` 출력을 PR 본문에 붙인다
  - main 빌드는 `git worktree add`로 다른 폴더에 받지 말고 `git stash`도 쓰지 말 것. `git archive main | tar -x -C <scratch 폴더>`로 풀어서 그 폴더에서 `xcodegen generate` 후 빌드한다

## Task 3 — 「장소별」 탭 (App)

- `ContentView`의 `TabView`에 넷째 탭 `tab("장소별", systemImage: "map") { PlacesView() }`
- `PlacesView`: `@Query`로 `Moment`를 읽어 `latitude`·`longitude`가 둘 다 있는 것만 `Map { ForEach … Marker(장소 이름 또는 제목, coordinate:) }`. 0개면 지도 위 `.overlay`에 `ContentUnavailableView("아직 장소가 있는 일정이 없다", systemImage: "map", description: Text("사진을 읽는 기능이 들어오면 여기에 보인다."))`
- `MomentRow`: `placeName`이 있으면 `.caption`으로 한 줄 더
- 시뮬레이터에서 「장소별」 탭을 연 스크린샷을 찍어 PR 본문에 경로와 함께 설명한다(`xcrun simctl io "$UDID" screenshot <scratch>/places.png`). 탭 전환은 DEBUG 전용 launch argument(예: `-openTab places`)로 해도 된다

## Task 4 — 마무리

- `README.md`: 「장소별」 탭이 지금은 비어 있다는 것, 장소는 #158~#159에서 사진으로 채운다는 것 한두 줄
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
   ls "$APP/PlugIns/WithWhomWidget.appex"
   UDID=$(xcrun simctl list devices available | grep 'iPhone 17 Pro (' | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
   xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl install "$UDID" "$APP"
   xcrun simctl launch "$UDID" com.jongwoo315.withwhom -autoImport && sleep 5 && xcrun simctl spawn "$UDID" launchctl list | grep -q withwhom && echo BOOT_OK
   xcrun simctl shutdown "$UDID"
   ```
   빌드 경로가 다르면 `xcodebuild -showBuildSettings`의 `BUILT_PRODUCTS_DIR`을 쓴다. 저장 모델에 칸이 늘어도 기존 저장 파일을 연 채 앱이 뜨는지가 이 확인의 요점이다(Task 2의 main 먼저 설치 순서) — 설치 전에 `xcrun simctl uninstall`하지 말 것
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 main과 같아야 한다

## Done criteria

- 통과 기준 1~5가 사실이고, Pre-PR 2번 출력(appex 경로, `BOOT_OK`), `PRAGMA table_info(ZMOMENT)` 출력, 스크린샷 경로를 PR 본문에 붙인다
- `Core/Tests/WithWhomCoreTests/Resources/titles.json`을 고치지 않는다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문(가리키는 제목 포함) + 「기기 마이그레이션 측정은 PR 게이트에서 main이 한다(실패 징후 1 (다))」 + 루프가 잰 것(장소 열 3개 여부, 「장소별」 탭 스크린샷, 장소 값이 든 일정 수, `MEASURE` 두 줄)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`docs:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #157의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40841e61-65c0-81c8-b6ea-ea3dacdf969f /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
- 공개 repo다. 테스트·문서에 jw 캘린더의 실제 이름을 넣지 않는다(가명만)
- 시뮬레이터를 켰으면 끝나기 전에 끈다(`xcrun simctl shutdown`)
