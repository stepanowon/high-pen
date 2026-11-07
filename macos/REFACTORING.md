# macOS 코드 정리 기록

2026-11-04 코드 검토에서 나온 리팩토링 후보는 1.4.1에서 모두 반영했다. 이 문서는 무엇을 바꿨는지, 그리고 남은 한계를 적어 둔다.

## 반영한 정리 (1.4.1)

- 명령 실행 코드는 단축키 목록 하나에만 있다. 툴바 버튼은 `hotkeys.action(id).run`을 그대로 쓴다. 예외는 지우개 버튼(전체 지우기 없이 지우개만 켜고 끔)과 정보 버튼(단축키 없음)이다.
- 칠판 종류는 `enum Board`가 맡는다. 배경색과 제목 키도 여기에 있다.
- 반복되는 UI 조각은 `Theme.swift`로 모았다: `bordered`, `pad`, `wrapLabel`, `repeatingTimer`, 이름 있는 색(`warnColor`, `alertRed`, `linkColor`).
- 팝업은 공용 `Popup`(`isOpen`/`present`/`close`)을 바탕으로 한다.
- `applyMode`는 `applyTool`(도구·페이지)과 `syncToolbar`(툴바 표시·위치)로 나눴다.
- 화면 캡처 설정은 `ScreenCapture.setup` 한 곳에 있다.

## Windows 변경 반영

- **1.8.6 → macOS 1.4.1:** 되돌리기 기록을 페이지마다 200단계로 제한했다(`InkView.maxSteps`).
- **1.8.7 → macOS 1.4.2:**
  - 확대 중 실제 커서를 원본 내용 위에 숨기고, 확대 화면 위에 커서를 그린다(`Zoomer`).
  - 화면은 보이는 영역 끝에서만 움직인다(`Zoomer.pan`).
  - 백그라운드 앱이 커서를 숨기려면 비공개 API `CGSSetConnectionProperty("SetsCursorInBackground")`가 필요하다.
  - 펜 모드, 쉬는 시간, 캡처 중에는 실제 커서를 보인다(`Controller.applyZoomPointer`).
- **1.8.9 → macOS 1.4.3:**
  - 맨 위·맨 아래에 붙는 가로 툴바. 끌기는 `Toolbar.drag`가 직접 처리하고, 붙은 끝은 `Cfg.barEdge`에 저장한다.
  - 가로일 때 설정 패널은 4열이다(`SettingsPanel.wideColumns`).
  - 툴바 위에서 모니터 끝에 포인터를 대고 있으면 확대 화면이 이동한다(`Zoomer.panFromEdge`).
  - Windows README의 "툴팁도 함께 확대된다"는 안내는 macOS에 해당하지 않는다. 힌트 창은 확대 영상에서 빠지기 때문이다.

## 메모리 주의점

- **설정 패널은 다시 만들지 않는다.** 만들 때마다 AppKit 객체가 쌓였다. 설정 패널 전체를 다시 만드는 것은 언어 변경이나 단축키 변경처럼 드문 경우뿐이고, 체크박스 같은 값은 해당 컨트롤만 갱신한다.
- **버튼 제목이 생겼다 사라지지 않게 한다.** macOS 26에서는 `imagePosition`을 바꾸면 그때마다 `NSKeyValueDependency` 등이 약 20~30개씩 남는다. 그래서 툴바 버튼은 아이콘과 제목을 한 이미지로 그린다(`Toolbar.showFace`).
- **설정 패널은 보일 때만 재배치한다.** 컨트롤을 다시 배치할 때도 같은 객체가 남는다. 그룹은 한 컨테이너에 둔 채 제약만 바꾼다.
- **확대를 끈 뒤 들어온 프레임은 버린다.** 그러지 않으면 숨은 레이어가 화면 이미지를 다시 붙잡는다(`guard s === stream`).

검증 방법은 다음과 같다. CGEvent로 같은 조작을 수십 번 반복하고, 그 전후의 `heap` 객체 수를 종류별로 비교한다. 늘어난 객체가 있으면 `MallocStackLogging=1`로 앱을 띄운 뒤 `malloc_history`로 할당 위치를 찾는다. `leaks`가 보고하는 288건은 시스템 쪽 항목이다.

## 알려진 한계

- 숨긴 포인터는 다음 업데이트(최대 한 프레임) 때 모니터 안으로 되돌린다. 그래서 그 사이 잠깐 옆 모니터에 있을 수 있다. 막으려면 이벤트 탭이 필요하다.
- 시스템이 커서를 다시 보이게 하는 경우(Mission Control 등)는 감지하지 못한다. 확인에 쓰던 `CGCursorIsVisible`을 macOS에서 더 이상 쓸 수 없다.
- 설정 패널이 화면보다 높으면 스크롤 없이 잘린다.
- 다른 앱에서 드래그하는 중에 캡처나 쉬는 시간 단축키를 누르면 포인터가 표시 위치로 옮겨진다(Windows와 같음).
