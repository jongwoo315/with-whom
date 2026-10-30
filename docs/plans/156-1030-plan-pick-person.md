# #156 확인 필요에서 사람을 골라 사전에 넣는다

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

**Tier:** B — 새 저장 모델(`Alias`)과 새 화면, 저장된 일정을 다시 해석해 고치는 동작. 별칭은 가져오기로 다시 만들 수 없는 첫 데이터다
**Notion:** #156 https://app.notion.com/p/40841e6165c081678146ebbb9661e6a7
**설계:** /Users/jw/prv/.wt/156-pick-person/docs/plans/156-1030-design-pick-person.md, 앱 설계 /Users/jw/prv/with-whom/docs/superpowers/specs/2026-10-28-with-whom-design.md §2
**흐름:** 이미 있다(캘린더 → 제목 해석 → 저장 → 앱 화면·위젯). 바꾸는 단계는 제목 해석의 사람 사전(`PersonDictionary`: 연락처만 → 연락처 + 별칭)이고, 확인 필요 화면에 입력이 하나 생긴다

## jw 기준

확인 필요 일정에서 사람을 직접 고르면 그 이름을 사전에 넣고, 같은 이름이 든 다른 일정도 다시 해석한다

## 통과 기준

1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두). 별칭이 없으면 사전이 지금과 똑같이 동작한다
2. 별칭 테스트(Task 1 표)가 통과한다
3. 앱이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`). 위젯 appex도 그대로 들어 있다
4. 확인 필요 탭에서 일정을 누르면 사람 고르기 화면이 열린다. 저장하면 별칭이 저장 파일에 들어가고, 같은 낱말이 든 저장된 일정이 그 자리에서 다시 해석된다(시뮬레이터에서는 화면이 열리는 것까지, 다시 해석은 Core 테스트로 보인다)

## 실패 징후

1. **jw 기준을 재는 것.** PR 게이트에서 main이 jw 아이폰에 설치하고, jw가 확인 필요에서 일정 몇 개(연인 호칭 1개 이상, 가족 호칭 1개 이상)에 사람을 고른다. main은 App Group 저장 파일을 복사해 센다. 세는 것: 저장된 별칭마다, 제목을 해석 규칙대로 낱말로 나눴을 때(🤍 제거, ` - ` 앞뒤, 공백·쉼표 나눔, 접미사 떼기) 그 별칭 낱말이 나오는 일정 중 그 사람이 붙지 않았거나 아직 확인 필요인 일정 수
   - 통과: 0개. 별칭 낱말이 든 일정이 전부 그 사람에 붙고 확인 필요에서 빠졌다
   - 다시 잰다: 1~2개. 남은 일정의 제목 꼴을 본다(띄어쓰기 없이 붙은 꼴이면 설계 「위험」의 알려진 한계다)
   - 미완: 3개 이상이거나, jw가 고른 바로 그 일정이 확인 필요에 남는다
   - 같이 적는 값: 고르기 전후 확인 필요 수. baseline은 #163 게이트(2026-10-30) 51개
2. 엉뚱한 일정에 사람이 붙었다. 별칭 낱말이 제목에 없는데 그 사람이 새로 붙은 일정 수
   - 통과: 0개
   - 다시 잰다: 1개. 그 제목을 본다
   - 미완: 2개 이상
3. 가져오기를 다시 누르면 고른 것이 되돌아간다. 게이트에서 고른 뒤 가져오기를 한 번 더 누르고 1번을 다시 센다. 값이 같아야 한다
4. `MEASURE` 줄 값이 main과 달라졌다

## 이번에 안 하는 것

- 별칭 지우기·고치기 화면 — 설계 「위험」에 적었다. 후속 티켓
- 띄어쓰기 없이 붙은 제목에서 낱말 일부만 고르기(「엄마생일」의 「엄마」)
- 일정 하나만 따로 사람을 지정하기 — 사전만 바꾼다(설계 「정한 것」 마지막 줄)
- 확인 필요가 아닌 일정(사람이 잘못 붙은 일정) 고치기
- 위젯 화면 변경 — 다시 해석이 끝나면 위젯 갱신만 요청한다
- 실제 기기 검증 — 실패 징후 1~3은 PR 게이트에서 main이 잰다

## Task 1 — 별칭을 받는 사전 (Core, TDD)

- `PersonDictionary.init(contacts:aliases:)` — `aliases: [String: String]`(낱말 → 사람 이름), 기본값 `[:]`. 기존 `init(contacts:)` 호출부는 그대로 동작한다
- 별칭 낱말도 연락처 이름과 같은 방식으로 찾는다(그대로, 또는 접미사를 뗀 꼴). 같은 키가 연락처와 별칭에 다 있으면 별칭이 우선한다
- `PersonDictionary.baseForm(_ token: String) -> String` — 끝의 접미사(기존 목록, 긴 것부터)를 하나 뗀 꼴. 떼고 남는 글자가 없으면 그대로 돌려준다
- `TitleParser.tokens(_ title: String) -> [String]` — `parse`와 같은 규칙으로 나눈 낱말 목록(순서 유지, 중복 제거). 화면이 고를 후보로 쓴다. `parse`가 이 함수를 같이 쓰게 바꿔도 된다(`MEASURE`가 그대로여야 한다)
- 테스트 견본 (사람 이름은 가명)

| 입력 | 기대 |
| --- | --- |
| 연락처 없음, 별칭 `["가람": "가람"]`, 제목 `가람이 🤍 - 북엇국, 호머` | `.auto(people: ["가람"], items: ["북엇국", "호머"])` |
| 같은 별칭, 제목 `가람이랑 영화` | `.auto(people: ["가람"], items: ["영화"])` |
| 연락처 `나래`, 별칭 `["나래": "다솜"]`, 제목 `나래 점심` | 사람 `다솜` (별칭이 우선) |
| 별칭 `["엄마": "엄마"]`, 제목 `엄마생일` | `.review` (붙은 낱말은 안 잡힌다) |
| `baseForm("가람이랑")`, `baseForm("엄마")`, `baseForm("이")` | `가람`, `엄마`, `이` |
| `tokens("가람이 🤍 - 북엇국, 호머 맥주")` | `["가람이", "북엇국", "호머", "맥주"]` |

## Task 2 — 별칭 저장과 다시 해석 (App)

- `App/Models.swift`에 `@Model final class Alias { @Attribute(.unique) var token: String; var personName: String }`. `SharedStore.makeContainer()`의 모델 목록에 넣는다(위젯도 같은 함수를 쓰므로 같이 바뀐다)
- 사전을 만드는 곳을 하나로 모은다: 연락처 + 저장된 `Alias` → `PersonDictionary`. `Importer.run`이 이것을 쓴다
- 다시 해석 함수: 저장된 `Moment` 전부를 새 사전으로 `TitleParser.parse` 해서 `people`·`items`·`needsReview`를 고친다. 사람 찾기·새 `Person` 만들기는 `Importer.upsert`의 방식을 같이 쓴다(중복 코드를 만들지 말고 나눠 쓸 함수로 뺀다). 저장 뒤 `WidgetCenter.shared.reloadAllTimelines()`
- 연락처를 못 읽었으면 다시 해석하지 않는다(`Importer`가 이미 「연락처를 못 읽은 실행은 기존 사람을 지우지 않는다」로 지키는 것과 같은 이유). 별칭 저장은 그대로 하고 문장으로 알린다
- 순수 로직은 Core 테스트로 보인다. 저장 파일을 쓰는 부분은 `ModelConfiguration(isStoredInMemoryOnly: true)`로 테스트할 수 없으면(앱 target에 테스트 target이 없다) 그 사실을 PR 본문에 적는다

## Task 3 — 사람 고르기 화면 (App)

- 확인 필요 탭의 행을 누르면 시트를 연다
  - 맨 위에 제목 원문
  - `TitleParser.tokens`로 나눈 낱말을 버튼으로 보인다. 하나를 고르면 아래 「별칭」 칸에 `baseForm`을 채운다(jw가 고칠 수 있다)
  - 「누구인가」: 이미 있는 사람 목록(이름순) 중 하나, 또는 「새 사람」(이름 칸, 기본값은 별칭 칸 값)
  - 「저장」: `Alias`를 넣고(같은 낱말이 있으면 사람 이름을 바꾼다) 다시 해석을 돌린 뒤 시트를 닫는다. 끝 메시지에 「별칭 X를 넣었다. 일정 N개가 다시 해석돼 확인 필요에서 M개가 빠졌다.」
  - 별칭 칸이나 사람 이름이 비면 「저장」을 막는다

## Task 4 — 마무리

- `README.md`: 확인 필요에서 사람 고르기 한 줄, 별칭은 다시 만들 수 없는 데이터라는 것, 지우는 화면이 아직 없다는 것
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
   빌드 경로가 다르면 `xcodebuild -showBuildSettings`의 `BUILT_PRODUCTS_DIR`을 쓴다. 저장 모델이 하나 늘어도 기존 저장 파일을 연 채 앱이 뜨는지가 이 확인의 요점이다 — 설치 전에 `xcrun simctl uninstall`하지 말 것
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 main과 같아야 한다

## Done criteria

- 통과 기준 1~4가 사실이고, 위 Pre-PR 2번 출력(appex 경로, `BOOT_OK`)을 PR 본문에 붙인다
- `Core/Tests/WithWhomCoreTests/Resources/titles.json`을 고치지 않는다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문 + 「기기 측정은 PR 게이트에서 main이 한다(실패 징후 1~3)」 + 루프가 잰 것(별칭 테스트 결과, `MEASURE` 두 줄, 시뮬레이터 확인 출력)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`docs:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #156의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40841e61-65c0-8167-8146-ebbb9661e6a7 /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
- 공개 repo다. 테스트·문서에 jw 캘린더의 실제 이름을 넣지 않는다(가명만)
