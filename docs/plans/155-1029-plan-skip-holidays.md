# #155 가져오기에서 공휴일 캘린더 일정을 뺀다

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

**Tier:** B — 앱·Core 두 곳에 걸친 새 로직, 이미 가져온 데이터를 지우는 동작이 있다. 되돌리기는 쉽다(가져오기로 다시 만든다)
**Notion:** #155 https://app.notion.com/p/40841e6165c081e69c74e56b8534d6cd
**설계:** /Users/jw/prv/with-whom/docs/plans/155-1029-design-skip-holidays.md (이 워크트리의 같은 경로), 앱 설계 /Users/jw/prv/with-whom/docs/superpowers/specs/2026-10-28-with-whom-design.md §4 「구글 캘린더가 안 보이면」
**흐름:** 이미 있다(#154). 바꾸는 단계는 `CalendarSource`(어느 캘린더를 읽나)와 `Importer`(뺀 캘린더 일정 지우기)다

## jw 기준

앱의 확인 필요 탭에서 공휴일이 나오지 않는다

## 통과 기준

1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두)
2. `CalendarFilter`의 기본값 테스트가 아래 캘린더 견본에서 정확히 공휴일·생일 캘린더만 뺀다
3. 앱이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`)
4. 툴바 「캘린더」 버튼으로 캘린더 목록 화면이 열리고, 캘린더마다 켜고 끄는 스위치가 있다. 끈 캘린더의 일정은 다음 가져오기에서 들어오지 않고, 이미 들어와 있던 것은 지워진다

## 실패 징후

1. **jw 기준을 재는 것.** 무인 루프는 jw 아이폰에 설치할 수 없다. PR 게이트에서 main 세션이 jw 아이폰에 설치하고, jw가 캘린더 화면을 확인(필요하면 스위치 조정)한 뒤 가져오기를 돌린 저장 파일을 복사해 센다. 세는 것: 확인 필요(`needsReview = 1`) `Moment` 중 제목이 아래 「공휴일 제목 목록」에 있는 수
   - 통과: 0개
   - 다시 잰다: 1~3개. 그 일정이 어느 캘린더에서 왔는지 보고, 기본값 규칙을 고칠지 jw가 화면에서 끄면 되는지 정한다
   - 미완: 4개 이상
   - 같이 적는 값: jw가 스위치를 하나도 안 건드린 기본값만으로 남은 수. baseline은 2026-10-29 실측 40개다
2. 공휴일이 아닌 일정까지 빠졌다. 2026-10-29 실측에서 공휴일이 아닌 `Moment`는 66개(106 − 40)였다. 게이트 측정에서 공휴일이 아닌 `Moment`가 66개보다 적으면 다른 캘린더까지 뺀 것이다(그 사이 새 일정이 생겨 늘어나는 것은 정상)
   - 통과: 66개 이상
   - 다시 잰다: 60~65개. 빠진 일정의 캘린더를 본다
   - 미완: 59개 이하
3. `MEASURE` 줄 값이 main과 달라졌다. 이 티켓은 제목 해석을 건드리지 않는다

### 공휴일 제목 목록 (2026-10-29 실측 40개에서 뽑은 서로 다른 제목)

크리스마스 이브, 크리스마스, 섣달 그믐날, 새해첫날, 설날 연휴, 설날, 삼일절, 삼일절(대체 휴일), 쉬는 날 삼일절, 식목일, 노동절, 어린이날, 어버이날, 스승의날, 부처님오신날, 부처님오신날(대체 휴일), 쉬는 날 부처님오신날, 지방선거일, 지방 선거일, 현충일, 제헌절, 광복절, 쉬는 날 광복절, 광복절(대체 휴일), 추석 연휴, 추석, 국군의날, 개천절, 개천절(대체 휴일), 쉬는 날 개천절, 한글날

## 이번에 안 하는 것

- 일정 제목으로 공휴일 거르기 — 캘린더 단위로만 뺀다(설계 문서 「정한 것」)
- 사람이 없는 일반 일정(헤어컷, 치과 등)은 확인 필요가 맞는 자리라 그대로 둔다
- 확인 필요 편집, 사람 사전 추가 — #156
- 저장 파일을 App Group으로 옮기기 — #163
- 실제 기기 검증 — 무인 루프는 jw 아이폰에 설치할 수 없다. 실패 징후 1·2는 PR 게이트에서 main이 잰다

## Task 1 — `CalendarFilter` (Core, 순수 함수)

- `EventInput`에 `calendarId: String`을 더한다. init 인자는 기본값 `""`을 줘서 기존 테스트 호출부를 안 바꿔도 되게 한다
- `CalendarInfo`(id, title, sourceTitle, kind) — `kind`는 Core 안 enum(`local`·`calDAV`·`exchange`·`subscription`·`birthday`·`other`). EventKit 타입을 Core에 들이지 않는다
- `CalendarFilter.defaultExcluded(_ calendars: [CalendarInfo]) -> Set<String>`: `kind`가 `subscription`·`birthday`이거나, `title`에 「휴일」 또는 「holiday」(대소문자 무시)가 들어가면 뺀다
- `CalendarFilter.split(_ events: [EventInput], excluded: Set<String>) -> (kept: [EventInput], droppedIds: Set<String>)`
- 테스트 견본 (TDD로 먼저 쓴다)

| title | sourceTitle | kind | 기본값 |
| --- | --- | --- | --- |
| 대한민국 공휴일 | 기타 | subscription | 뺀다 |
| 대한민국의 휴일 | jw@gmail.com | calDAV | 뺀다 |
| Holidays in South Korea | iCloud | calDAV | 뺀다 |
| 생일 | 기타 | birthday | 뺀다 |
| jw@gmail.com | jw@gmail.com | calDAV | 둔다 |
| 홈 | iCloud | calDAV | 둔다 |
| 캘린더 | 나의 iPhone | local | 둔다 |

## Task 2 — 가져오기가 뺀 캘린더를 지킨다 (App)

- `CalendarSource`: 캘린더 목록(`[CalendarInfo]`, `EKCalendar.type`을 Core enum으로 옮긴다)과 일정(각 일정에 `event.calendar.calendarIdentifier`)을 같이 돌려준다
- 뺀 캘린더 id는 `UserDefaults` 키 `excludedCalendarIds`(문자열 배열)에서 읽는다. 키가 없으면 `CalendarFilter.defaultExcluded`를 쓴다
- `Importer`: `split`으로 나눠 `kept`만 `MomentBuilder`에 넘긴다. `droppedIds`와 `sourceId`가 같은 기존 `Moment`는 지운다. `Person`에 남은 `Moment`가 0개여도 `Person`은 지우지 않는다(사람 목록 화면이 이미 빈 사람을 숨긴다)
- 끝 메시지에 뺀 수를 붙인다: 「일정 N개를 가져왔다. 뺀 캘린더 일정 M개는 넣지 않았다.」

## Task 3 — 캘린더 고르기 화면 (App)

- 툴바에 「캘린더」 버튼. 누르면 시트로 캘린더 목록을 연다. `sourceTitle`별로 묶고, 캘린더마다 이름과 스위치(켜짐 = 읽는다)
- 처음 열 때 스위치 상태는 저장된 값, 없으면 기본값이다. 스위치를 바꾸면 바로 `UserDefaults`에 저장한다
- 시트를 닫으면 가져오기를 한 번 다시 실행한다(그래야 끈 캘린더 일정이 바로 지워진다)
- 캘린더 권한이 없으면 목록 대신 권한 안내 문장을 보인다

## Task 4 — 마무리

- `README.md`에 캘린더 화면 한 줄과 기본값 규칙을 적는다
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
2. 앱 실행 확인 (서버 대신). 시뮬레이터는 끝나면 반드시 끈다. `-scheme -destination` 빌드가 destination을 못 찾으면 README에 적힌 `-target WithWhom -sdk iphonesimulator` 방식으로 빌드한다
   ```bash
   xcodegen generate
   xcodebuild -project WithWhom.xcodeproj -scheme WithWhom -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build | tail -5
   UDID=$(xcrun simctl list devices available | grep 'iPhone 17 Pro (' | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
   xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/WithWhom.app
   xcrun simctl launch "$UDID" com.jongwoo315.withwhom -autoImport && sleep 5 && xcrun simctl spawn "$UDID" launchctl list | grep -q withwhom && echo BOOT_OK
   xcrun simctl shutdown "$UDID"
   ```
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 main과 같아야 한다

## Done criteria

- 통과 기준 1~4가 사실이다. 4번 중 화면은 시뮬레이터 실행으로, 지우기 동작은 Core 테스트 또는 `Importer` 로직을 나눈 함수 테스트로 보인다
- `Core/Tests/WithWhomCoreTests/Resources/titles.json`을 고치지 않는다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문 + 「기기 측정은 PR 게이트에서 main이 한다(실패 징후 1·2)」 + 루프가 잰 것(기본값 테스트 결과, `MEASURE` 두 줄)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`docs:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #155의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40841e61-65c0-81e6-9c74-e56b8534d6cd /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
