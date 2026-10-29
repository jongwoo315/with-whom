# with-whom

캘린더 일정 제목에서 누구와·언제·무엇을 했는지 뽑아 사람별·날짜별로 다시 찾아보는 iPhone 앱이다. 서버 없이 기기 안에서만 동작한다. 지금은 EventKit 일정과 연락처 이름만 읽고, 사진·지도는 다음 티켓이다. 설계는 `docs/superpowers/specs/2026-10-28-with-whom-design.md`에 있다.

## 판단 기록

구현은 AI 에이전트가 했고, 티켓마다 무엇을 성공으로 볼지는 jw가 착수 전에 먼저 한 줄로 썼다. PR이 열리면 결과를 그 한 줄과 맞춰 보고 jw가 판정했다. 2026-10-28부터 쌓았다.

티켓 1개 · jw 판정 통과 1 · 반려 0 · 유보 0

착수 전 기준과 결과가 갈린 티켓은 아직 없다. 전체는 [`docs/decisions.md`](docs/decisions.md)에 있다.

## 빌드와 테스트

```bash
cd Core && swift test          # 제목 해석 테스트와 측정
xcodegen generate              # project.yml → WithWhom.xcodeproj (생성물도 커밋돼 있다)
xcodebuild -project WithWhom.xcodeproj -target WithWhom -sdk iphonesimulator -configuration Debug build
```

- 앱 target은 `Core/Sources/WithWhomCore`를 직접 컴파일한다. package로 의존하면 Xcode 26.5에 iOS 26.2 시뮬레이터 런타임만 깔린 기기에서 빌드 대상이 하나도 안 잡혔다. 그래서 `-scheme`/`-destination` 대신 `-target`/`-sdk`로 빌드한다
- 시뮬레이터에서 버튼 탭 없이 가져오기를 돌리려면 Debug 빌드를 `-autoImport` 인자로 실행한다: `xcrun simctl launch <UDID> com.jongwoo315.withwhom -autoImport`

## 캘린더 고르기

- 툴바 「캘린더」 버튼으로 캘린더 목록이 열리고, 캘린더마다 읽을지 켜고 끄는 스위치가 있다. 시트를 닫으면 가져오기가 한 번 다시 돌고, 끈 캘린더의 일정은 새로 들어오지 않으며 이미 들어온 것은 지워진다
- 저장된 선택이 없을 때 기본값은 종류가 구독·생일인 캘린더와, 이름에 「휴일」·「holiday」(대소문자 무시)가 든 캘린더를 뺀 상태다. 규칙은 `Core/Sources/WithWhomCore/CalendarFilter.swift`에 있다
- 이름에 「휴일」이 든 일반 캘린더(예: 「주말·휴일 약속」)도 기본값에서는 빠지고, 이미 들어온 그 일정은 다음 가져오기에서 지워진다. 필요하면 화면에서 켠다
- 선택은 `UserDefaults` 키 `excludedCalendarIds`에, 그때 보인 캘린더 id는 `knownCalendarIds`에 저장한다. 저장한 뒤에 새로 생긴 캘린더에도 기본값 규칙이 적용된다
- 지우기는 가져오는 기간(1년 전 ~ 30일 뒤)에 든 일정만 대상이다. 그보다 오래된 일정은 남는다

## 측정 줄 읽는 법

`swift test`는 연락처 꼴(`split`: 성·이름 분리, `fullInGiven`: 이름 칸에 전체 이름) 둘로 견본 31개를 돌려 한 줄씩 출력한다.

```
MEASURE shape=split auto_ok=25/25 review=5 wrong=1
```

- `auto_ok`: 정답이 `auto`인 25개 중 사람과 항목이 정답과 똑같이 나온 수
- `review`: 해석기가 「확인 필요」로 보낸 수(정답이 `auto`든 `review`든)
- `wrong`: 자동으로 처리했는데 정답과 다르거나, 정답이 `review`인데 자동으로 처리한 수
- 케이스마다 `CASE shape=… n=…` 줄이 같이 나온다. 정답 파일은 `Core/Tests/WithWhomCoreTests/Resources/titles.json`이고 구현이 고치지 않는다
- 이 테스트는 값으로 실패하지 않는다. 정답 파일 형식이 깨졌을 때만 실패한다
