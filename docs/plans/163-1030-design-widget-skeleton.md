# #163 위젯 skeleton — 설계

## 왜

앱을 열어야만 보이는 기록은 잘 안 보게 된다. 홈 화면 위젯이 「오래 못 본 사람」을 보여 주면 앱을 열지 않아도
연락할 계기가 생긴다. 위젯은 앱과 다른 프로세스라 앱의 저장 파일을 바로 읽지 못한다. 그래서 저장 파일을 앱과
위젯이 같이 쓰는 App Group 폴더로 옮겨야 하고, 이 티켓이 그 길을 처음 낸다. 나머지 위젯(1년 전 오늘, 확인 필요,
이번 달)은 이 길 위에 얹는다.

## 착수 전에 확인한 것 (2026-10-30)

- 무료 Apple ID(Personal Team) 서명으로 App Group이 켜진다
  - 명령줄 빌드(`xcodebuild -allowProvisioningUpdates`)만으로는 실패했다: `Provisioning profile ... doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement`
  - jw가 Xcode 화면의 Signing & Capabilities에서 그룹을 한 번 등록한 뒤에는 명령줄 빌드가 성공했고, 서명된 앱에 `group.com.jongwoo315.withwhom`이 들어갔다
  - 위젯 확장은 App ID가 따로라(`com.jongwoo315.withwhom.widget`) 같은 등록을 한 번 더 해야 할 수 있다. 실기기 설치 때 확인한다. 무인 루프는 시뮬레이터로만 빌드하므로 여기에 안 걸린다

## 정한 것

| 무엇 | 고른 것 | 이유 |
| --- | --- | --- |
| 저장 파일 위치 | `ModelConfiguration(groupContainer: .identifier("group.com.jongwoo315.withwhom"))`. 앱과 위젯이 같은 함수로 컨테이너를 만든다 | 위젯이 앱의 데이터를 읽는 유일한 길이다 |
| 기존 저장 파일 | 옮기지 않는다. 새 위치는 비어서 시작하고 jw가 가져오기를 한 번 더 누른다 | 지금 저장된 것은 전부 캘린더에서 다시 만들 수 있다. 손으로 넣은 데이터는 #156부터 생긴다. 옛 파일은 지우지 않고 그대로 둔다 |
| 뺀 캘린더 설정(`UserDefaults`) | 그대로 앱 전용 `UserDefaults.standard` | 위젯이 읽을 일이 없다 (#155 설계) |
| 「오래 못 본 사람」 정의 | 지금 시각 이전에 시작한 `Moment`가 하나라도 있는 사람 중, 마지막 `Moment` 시작일부터 오늘까지 날 수가 가장 큰 사람. 날 수는 달력 날짜 차이 | 앞으로 잡힌 약속은 「만났다」가 아니다 |
| 고르는 로직 위치 | Core의 순수 함수 (이름·마지막 만난 시각 목록 + 지금 → 이름·날 수). 위젯은 SwiftData에서 목록만 만들어 넘긴다 | 기기 없이 `swift test`로 잰다 (설계 §5) |
| 위젯 크기 | 작은 위젯(`.systemSmall`) 하나 | 티켓 범위 |
| 비었을 때 | 「아직 만난 사람이 없다」 문구 | 가져오기 전에 위젯을 추가해도 깨지지 않게 한다 |
| 갱신 | 하루 한 번(다음 자정) + 앱이 가져오기를 끝내면 `WidgetCenter.shared.reloadAllTimelines()` | 날 수는 하루에 한 번만 바뀐다 |
| 위젯을 눌렀을 때 | 앱이 열린다(기본 동작). 사람 화면으로 바로 가지 않는다 | 다음 티켓이 할 일이다 |

## 안 고른 것

- 옛 저장 파일을 App Group으로 복사하기 — 다시 가져오기로 같은 결과가 나온다. 손으로 넣은 데이터가 생긴 뒤였다면 필요했다
- 위젯 전용으로 요약 값만 `UserDefaults(suiteName:)`에 써 두기 — 위젯 4개가 각각 다른 값을 원해서 결국 저장 파일을 같이 읽게 된다

## 위험

- 위젯 프로세스는 메모리 한도가 작다(약 30MB, 추정). 사람 수가 수백 명이면 전부 불러오는 쿼리가 문제가 될 수 있다. 지금은 사람이 수십 명이다
- 무료 서명은 7일마다 만료된다. 만료되면 앱과 함께 위젯도 안 뜬다
