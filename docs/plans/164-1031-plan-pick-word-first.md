# #164 사람 고르기 화면에서 낱말을 먼저 고르게 하고 저장이 막힌 이유를 보여 준다

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

**Tier:** B — 화면 순서 변경과 저장 조건을 Core 함수로 옮기기. 저장 모델·저장 로직은 안 바뀐다
**Notion:** #164 https://app.notion.com/p/40a41e6165c081ccbbdbc84fc8de5a47
**설계:** /Users/jw/prv/.wt/164-pick-word-first/docs/plans/164-1031-design-pick-word-first.md
**흐름:** 이미 있다(확인 필요 → 사람 고르기 → 별칭 저장 → 다시 해석). 이 티켓은 사람 고르기 화면(`App/PickPersonView.swift`)의 순서와 안내만 바꾼다

## jw 기준

사람 고르기 화면에서 낱말을 먼저 고르게 하고 저장이 막힌 이유를 보여 준다

## 통과 기준

1. `Core/`에서 `swift test`가 전부 통과한다. 기존 `MEASURE` 두 줄 값이 main과 같다(`auto_ok=25/25 review=5 wrong=1` 두 꼴 모두)
2. `PickRule.blockReason` 테스트(Task 1 표)가 통과한다
3. 앱과 위젯이 iPhone 17 Pro 시뮬레이터용으로 빌드되고 실행된다(`BOOT_OK`)
4. 시뮬레이터 스크린샷 셋(Task 3)이 PR 본문에 경로와 함께 있다

## 실패 징후

1. **jw 기준을 재는 것.** 시뮬레이터 스크린샷 셋과 Core 테스트로 잰다. PR 게이트에서 main이 스크린샷을 직접 연다
   - (가) 낱말을 고르기 전 화면(스크린샷 1)에 「누구인가」 칸(사람 목록·「새 사람」·이름 칸)이 하나도 없다
     - 통과: 하나도 없고 「위에서 낱말을 먼저 고른다」가 보인다
     - 다시 잰다: 칸은 없는데 안내 한 줄이 안 보인다(스크롤 밖인지 스크린샷을 다시 본다)
     - 미완: 「누구인가」 칸의 버튼이나 이름 칸이 하나라도 보인다
   - (나) 저장이 막히는 세 경우(별칭 빈 칸, 별칭에 띄어쓰기, 새 사람 이름 빈 칸)마다 서로 다른 이유 문장이 나온다. Core 테스트로 세 경우를, 스크린샷 1·3으로 앞의 두 경우가 화면에 보이는 것을 센다
     - 통과: 테스트 3/3, 화면 2/2
     - 다시 잰다: 테스트 3/3인데 화면 1/2(스크린샷 인자를 다시 본다)
     - 미완: 테스트가 하나라도 실패하거나 화면 0/2
   - (다) 저장할 수 있는 상태(스크린샷 2)에서는 이유 문장이 없고 저장 버튼이 눌린다(흐리지 않다)
     - 통과: 문장 없음, 버튼 활성
     - 다시 잰다: 버튼 활성 여부가 스크린샷으로 안 갈린다(접근성 트리나 색으로 다시 본다)
     - 미완: 문장이 남아 있거나 버튼이 비활성
2. 저장 조건이 바뀌었다. main에서 저장할 수 있던 입력이 이제 막히거나, 막히던 입력이 이제 저장된다. `PickRule.blockReason == nil`과 main의 `canSave` 조건(`isValidAliasKey(alias) && !personName.isEmpty`)이 Task 1 표 입력 전부에서 같아야 한다
   - 통과: 전부 같다 / 다시 잰다: 없음 / 미완: 하나라도 다르다
3. `MEASURE` 줄 값이 main과 달라졌다

## 이번에 안 하는 것

- 별칭 저장·다시 해석 로직(`Importer.pickPerson`) 변경
- 별칭 지우기·고치기 화면
- 화면을 여러 단계(NavigationLink)로 나누기
- 실제 아이폰 확인 — 저장 로직이 그대로라 시뮬레이터 스크린샷으로 판정한다

## Task 1 — 저장을 막는 이유 (Core, TDD)

- `Core/Sources/WithWhomCore/PickRule.swift`: `public enum PickRule { public static func blockReason(alias: String, personName: String) -> String? }`
  - 두 값 모두 앞뒤 공백을 자르고 판단한다
  - 순서: 별칭이 비었으면 문장 1 → 별칭이 `PersonDictionary.isValidAliasKey`를 통과 못 하면 문장 2 → 사람 이름이 비었으면 문장 3 → 아니면 `nil`
  - 문장 1: `위에서 낱말을 고르거나 별칭을 적어야 저장할 수 있다`
  - 문장 2: `별칭에는 띄어쓰기와 쉼표를 넣을 수 없다`
  - 문장 3: `새 사람 이름을 적어야 저장할 수 있다`
- 테스트 견본 (가명)

| alias | personName | 기대 |
| --- | --- | --- |
| `""` | `""` | 문장 1 |
| `"  "` | `"가람"` | 문장 1 |
| `"김 가람"` | `"가람"` | 문장 2 |
| `"가람,"` | `"가람"` | 문장 2 |
| `"가람"` | `""` | 문장 3 |
| `"가람"` | `"  "` | 문장 3 |
| `"가람"` | `"가람"` | `nil` |
| `" 가람 "` | `"나래"` | `nil` |

- 같은 표 입력마다 `(blockReason == nil) == (isValidAliasKey(trim(alias)) && !trim(personName).isEmpty)`를 확인하는 테스트 하나(실패 징후 2)

## Task 2 — 화면 순서와 이유 문장 (App)

- `PickPersonView`
  - `canSave`를 `PickRule.blockReason(alias: alias, personName: personName) == nil && !isSaving`으로 바꾼다
  - 「누구인가」 Section은 `PersonDictionary.isValidAliasKey(trimmedAlias)`일 때만 둔다. 아니면 그 자리에 `Section { Text("위에서 낱말을 먼저 고른다").foregroundStyle(.secondary) }`
  - 폼 맨 아래: `blockReason`이 `nil`이 아니면 `Section { Text(reason).foregroundStyle(.secondary) }`
  - 고른 사람(`existingName`)·적은 이름(`newName`)은 「누구인가」가 숨어도 지우지 않는다

## Task 3 — 시뮬레이터 확인 인자와 스크린샷 (App, DEBUG 전용)

- `#if DEBUG`로 launch argument 둘: `-pickPreview <제목>`이면 앱이 뜨자마자 그 제목으로 `PickPersonView` 시트를 연다. `-pickAlias <값>`이면 별칭 칸 처음 값을 그것으로 둔다. 기존 `-openTab`과 같은 방식으로 `CommandLine.arguments`를 읽는다
- 저장 파일에 일정이 없어도 열려야 한다(시뮬레이터는 일정 0개다)
- 스크린샷 셋(`xcrun simctl io "$UDID" screenshot <scratch>/pick-N.png`, 각 실행 사이에 `xcrun simctl terminate`)
  1. `-pickPreview "가람이 🤍 - 북엇국, 호머"` — 낱말 고르기 전
  2. 같은 제목 + `-pickAlias 가람` — 저장할 수 있는 상태
  3. 같은 제목 + `-pickAlias "김 가람"` — 별칭에 띄어쓰기
- 각 스크린샷을 직접 열어 실패 징후 1 (가)(나)(다)를 PR 본문에 적는다

## Task 4 — 마무리

- `README.md`의 사람 고르기 설명에 「낱말을 먼저 고르면 누구인가가 열린다, 막히면 이유가 아래에 나온다」 한 줄
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
   빌드 경로가 다르면 `xcodebuild -showBuildSettings`의 `BUILT_PRODUCTS_DIR`을 쓴다. 저장 모델은 바뀌지 않는다
3. 테스트: `cd Core && swift test 2>&1 | tail -60` — `MEASURE` 두 줄이 main과 같아야 한다

## Done criteria

- 통과 기준 1~4가 사실이고, Pre-PR 2번 출력(appex 경로, `BOOT_OK`)과 스크린샷 세 장의 경로를 PR 본문에 붙인다
- `Core/Tests/WithWhomCoreTests/Resources/titles.json`을 고치지 않는다: `git diff main...HEAD -- Core/Tests/WithWhomCoreTests/Resources/titles.json`이 비어 있다
- **PR 본문 맨 위에 `## 착수 전 기준 (jw)` 절** — plan의 `## jw 기준` 원문 + 루프가 잰 것(실패 징후 1 (가)(나)(다) 각각 스크린샷 번호와 함께, `PickRule` 테스트 결과, `MEASURE` 두 줄)
- 커밋 메시지는 `rules/github.md` 접두사(`feature:`·`test:`·`docs:` 등, 괄호 없음), 한글, Task 하나에 커밋 하나
- 커밋 이메일 `jongwoo315@gmail.com`, `gh` 계정 `jongwoo315`, PR base `main`
- PR 생성 후 Notion #164의 `PR` 속성을 PR URL로 고친다:
  ```bash
  printf '{"properties":{"PR":{"url":"%s"}}}' "<PR URL>" > /tmp/pr.json
  "$HOME/.claude/tools/notion-api/notion-api" PATCH /v1/pages/40a41e61-65c0-81cc-bbdb-c84fc8de5a47 /tmp/pr.json
  ```
- base 브랜치를 작업 브랜치에 merge·rebase하지 않는다
- 공개 repo다. 테스트·문서에 jw 캘린더의 실제 이름을 넣지 않는다(가명만)
- 시뮬레이터를 켰으면 끝나기 전에 끈다(`xcrun simctl shutdown`)
