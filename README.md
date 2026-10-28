# with-whom

캘린더 일정 제목에서 누구와·언제·무엇을 했는지 뽑아 사람별·날짜별로 다시 찾아보는 iPhone 앱이다. 서버 없이 기기 안에서만 동작한다. 지금은 EventKit 일정과 연락처 이름만 읽고, 사진·지도는 다음 티켓이다. 설계는 `docs/superpowers/specs/2026-10-28-with-whom-design.md`에 있다.

## 빌드와 테스트

```bash
cd Core && swift test          # 제목 해석 테스트와 측정
xcodegen generate              # project.yml → WithWhom.xcodeproj (생성물도 커밋돼 있다)
xcodebuild -project WithWhom.xcodeproj -target WithWhom -sdk iphonesimulator -configuration Debug build
```

- 앱 target은 `Core/Sources/WithWhomCore`를 직접 컴파일한다. package로 의존하면 Xcode 26.5에 iOS 26.2 시뮬레이터 런타임만 깔린 기기에서 빌드 대상이 하나도 안 잡혔다. 그래서 `-scheme`/`-destination` 대신 `-target`/`-sdk`로 빌드한다
- 시뮬레이터에서 버튼 탭 없이 가져오기를 돌리려면 Debug 빌드를 `-autoImport` 인자로 실행한다: `xcrun simctl launch <UDID> com.jongwoo315.withwhom -autoImport`

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
