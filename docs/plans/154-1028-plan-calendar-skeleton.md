# #154 캘린더 일정에서 누구와·언제·무엇을 뽑는 첫 흐름

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

**Tier:** B — 새 프로젝트, 새 로직이 여러 파일에 걸치지만 되돌리기 쉽다
**Notion:** #154 https://app.notion.com/p/with-whom-40741e6165c0818896e9c8919f778ed1
**설계:** /Users/jw/prv/with-whom/docs/superpowers/specs/2026-10-28-with-whom-design.md (§1 구조, §2 제목 규칙 해석이 이 티켓 범위)

## jw 기준

누구와 언제 무엇을 했는지 자동으로 파악이 된다

## 통과 기준

1. `Core/` Swift 패키지에서 `swift test`가 전부 통과한다
2. 측정 테스트가 견본 31개(`Core/Tests/WithWhomCoreTests/Resources/titles.json`)를 연락처 꼴 둘(`split`, `fullInGiven`)로 각각 돌리고 아래 줄을 출력한다
   ```
   MEASURE shape=<split|fullInGiven> auto_ok=<n>/25 review=<n> wrong=<n>
   ```
3. iOS 앱이 iPhone 17 Pro 시뮬레이터(iOS 26.2)용으로 빌드되고, 설치·실행하면 프로세스가 뜬다
4. 앱에서 「가져오기」를 누르면 EventKit 일정 → 반복 일정 제외 → 제목 해석 → SwiftData 저장이 한 번에 진행되고, 사람별·날짜별·확인 필요 세 목록에 나온다

## 실패 징후

1. **jw 기준을 재는 것.** 측정 줄의 두 연락처 꼴 중 **나쁜 쪽** 값으로 판정한다. 정답 25개(`expect: auto`)가 상한이다 <!-- style-exempt -->
   - 통과: `auto_ok` 24 이상이고 `wrong` 1 이하
   - 다시 잰다: `auto_ok` 18~23이거나 `wrong` 2~3. 놓친 케이스를 꼴별로 묶어 PR 본문에 적는다. 규칙을 더할지 B(기기 안 LLM)로 넘길지는 사람이 정한다
   - 미완: `auto_ok` 17 이하이거나 `wrong` 4 이상
   - baseline 없음 — 이번이 첫 측정이고, B 티켓의 기준값이 된다
2. `titles.json`의 `people`·`items`·`expect`를 구현 쪽에서 고쳤다. 정답 파일은 착수 전에 사람이 붙인 것이다. 바꾸면 측정이 무효다
3. `wrong`이 0인데 `review`가 6보다 크다. 사람을 못 찾아 전부 확인 필요로 보낸 것이라 자동 파악이 안 된 것이다

## 이번에 안 하는 것

- 사진 붙이기, 장소·역지오코딩·지도, Takeout, 확인 필요 편집 화면(목록만 보인다), 사람 사전 수동 추가·별칭 입력 화면, 기기 안 LLM — 다음 티켓
- `PhotoRef` 모델 — 사진 티켓에서 만든다
- 실제 기기 검증 — 무인 루프가 jw 아이폰에 설치할 수 없다. PR 리뷰 때 jw가 직접 설치해 본다

## 제목 해석 규칙 (정답 파일이 이 규칙을 따라 쓰였다)

- 제목에서 `🤍`를 지우고 앞뒤 공백을 지운다
- ` - `가 있으면 처음 ` - ` 앞을 왼쪽, 뒤를 오른쪽으로 나눈다. 오른쪽은 `,`로 나눠 항목 목록을 만든다(각 항목 trim). 없으면 제목 전체가 왼쪽이고 오른쪽 항목은 없다
- 왼쪽은 `,`와 공백으로 토큰을 나눈다
- 사람 찾기는 왼쪽 토큰과, 오른쪽 각 항목을 공백으로 나눈 토큰 모두에 한다
  - 토큰 끝에서 `이랑`·`랑`·`이가`·`가`·`이`·`씨`·`님`을 떼어 본 꼴과 원래 꼴 중 사전에 있는 것이 있으면 그 사람이다. 긴 접미사부터 떼어 본다
  - 사전에 없으면 사람이 아니다. 이름처럼 보여도 추측하지 않는다
- 항목 만들기
  - 왼쪽에서 사람 아닌 토큰을 원래 순서로 공백으로 이어 항목 하나로 만들고 맨 앞에 둔다(비면 안 넣는다)
  - 오른쪽 항목은 사람 토큰을 빼고 남은 토큰을 공백으로 잇는다. 비면 버린다
- 사람이 하나도 없으면 `review`다. 이때 항목은 제목 전체 하나다
- 사람 사전 만들기 (`PersonDictionary`)
  - 연락처마다 `given`, `family+given`을 넣는다
  - `family`가 비고 `given`이 한글 3글자면 뒤 2글자도 넣는다(`김가람` → `가람`)
  - 사전의 값은 그 사람의 대표 이름(`given`에서 위 규칙으로 얻은 2글자 꼴, 없으면 `given`)이다. 정답 파일의 `people`은 이 대표 이름이다
  - 별칭은 이번에 받지 않는다(`자기` 등). 다음 티켓

## Task 1 — `WithWhomCore` 패키지와 제목 해석

- `Core/Package.swift`: library `WithWhomCore`, test target `WithWhomCoreTests`(resources: `Resources/titles.json` copy). platforms iOS 26, macOS 26. Swift Testing 사용
- `PersonDictionary(contacts: [Contact])`, `Contact(given:family:)`
- `TitleParser.parse(_ title: String, dictionary: PersonDictionary) -> ParseResult`
  - `enum ParseResult: Equatable { case auto(people: Set<String>, items: [String]); case review(items: [String]) }`
- TDD: 위 규칙 항목마다 실패하는 테스트부터 쓴다. 견본 31개가 아니라 규칙별로 짧은 입력을 쓴다

## Task 2 — 측정 테스트

- `MeasurementTests`: `titles.json`을 읽어 연락처 꼴 둘로 각각 31개를 돌린다
- 채점
  - `expect: auto`인데 `.auto`이고 `people` 집합과 `items` 배열이 같으면 `auto_ok`
  - `.review`를 돌려주면 `review` (정답이 `auto`든 `review`든)
  - `.auto`인데 정답과 다르거나 정답이 `review`면 `wrong`
- 케이스마다 `n`·결과·정답을 한 줄씩 출력하고 마지막에 `MEASURE` 줄을 출력한다
- 이 테스트는 임계값으로 실패시키지 않는다. 정답 파일 형식이 깨졌을 때만 실패한다

## Task 3 — 일정에서 `Moment` 초안 만들기 (순수 함수)

- `EventInput(id: String, title: String, start: Date, end: Date, isRecurring: Bool)`
- `MomentBuilder.build(_ events: [EventInput], dictionary:) -> [MomentDraft]`
  - 반복 일정은 뺀다
  - `MomentDraft(sourceId, date, start, end, title, people, items, needsReview)`. `date`는 기기 시간대 기준 시작일
- 테스트: 반복 일정 제외, 같은 id가 두 번 들어오면 하나만, `review` 결과는 `needsReview == true`

## Task 4 — iOS 앱

- `project.yml`(xcodegen)로 `WithWhom.xcodeproj`를 만든다. 생성된 `.xcodeproj`도 커밋한다(xcodegen 없이도 열리게)
  - target `WithWhom`, iOS 26.0, SwiftUI, bundle id `com.jongwoo315.withwhom`, local package `Core` 의존
  - Info.plist: `NSCalendarsFullAccessUsageDescription`, `NSContactsUsageDescription`
- SwiftData 모델 `Moment`(sourceId 고유, date, start, end, title, items, needsReview, people), `Person`(name 고유) — 다대다
- `CalendarSource`: `EKEventStore.requestFullAccessToEvents`, 오늘 기준 1년 전 ~ 30일 뒤 일정 → `EventInput`(`isRecurring = event.hasRecurrenceRules`, id는 `calendarItemExternalIdentifier`)
- `ContactsSource`: `CNContactStore`에서 given·family만 읽어 `Contact`로
- `Importer`: 두 소스 → `MomentBuilder` → `sourceId`로 upsert. 권한이 거부되면 화면에 문장으로 알리고 멈추지 않는다
- 화면: `TabView` 셋 — 사람별(사람 → 그 사람의 `Moment` 목록, 최신순), 날짜별(최신순, 사람·항목 표시), 확인 필요(`needsReview`만). 툴바에 「가져오기」 버튼
- 사진·지도 탭은 만들지 않는다

## Task 5 — 마무리

- `README.md`: 한 문단 소개, 빌드 방법(`xcodegen generate`, `swift test`), 측정 줄 읽는 법
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
2. 앱 실행 확인 (서버 대신). 시뮬레이터는 끝나면 반드시 끈다
   ```bash
   xcodegen generate
   xcodebuild -project WithWhom.xcodeproj -scheme WithWhom -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build | tail -5
   UDID=$(xcrun simctl list devices available | grep 'iPhone 17 Pro (' | head -1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
   xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl install "$UDID" build/Build/Products/Debug-iphonesimulator/WithWhom.app
   xcrun simctl launch "$UDID" com.jongwoo315.withwhom && sleep 5 && xcrun simctl spawn "$UDID" launchctl list | grep -q withwhom && echo BOOT_OK
   xcrun simctl shutdown "$UDID"
   ```
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 보여야 한다

## Done criteria

- 통과 기준 1~4가 사실이다. 4는 시뮬레이터에 일정이 없어도 「가져오기」가 오류 없이 끝나고 빈 목록이 보이면 된다
- `titles.json`이 착수 커밋과 바이트가 같다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문 + 그 기준으로 잰 결과(`MEASURE` 두 줄, 나쁜 쪽으로 본 실패 징후 1번 구간, `wrong`·`review` 케이스 번호와 그때 돌려준 값)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`add:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #154의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40741e61-65c0-8188-96e9-c8919f778ed1 /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
