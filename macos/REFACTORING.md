# macOS 코드 리팩토링 후보

2026-11-04 코드 검토 결과. 동작 오류가 아니라 구조·중복 개선 후보이며, 실제 Mac에서 빌드·실행해 확인하며 진행한다.
줄 번호는 검토 시점(커밋 `f7957a9`) 기준.

**상태: 1~5와 사소함 항목 모두 반영함 (브랜치 `refactor/macos`).** 함께 반영한 것:
- Windows 1.8.6: 되돌리기 기록을 페이지마다 최근 200단계로 제한(`InkView.maxSteps`), 툴바 드래그 중 모니터 영역을 다시 읽지 않음. 스폿 타이머 정지와 같은 뷰 재처리 생략은 macOS에 이미 있었음. 1.8.5(DPI 가상화)는 Windows 전용.
- 메모리: 확대를 끈 뒤 늦게 도착한 프레임이 숨은 레이어에 화면 이미지를 다시 붙잡던 것, 확대를 빠르게 두 번 누르면 스트림이 두 개 열리던 것, 키 이벤트 모니터를 보관하지 않던 것, 압력·클릭 표시 단축키가 설정 패널 전체를 다시 만들며 AppKit 객체가 쌓이던 것(250회 반복 시 블록·KVO 객체 약 1만 1천 개 차이), 토스트가 닫힌 뒤에도 창을 붙잡던 것. 쉬는 시간 화면은 표시가 바뀔 때만 다시 그림.
- Windows 1.8.7 (2026-11-07): 확대 중 실제 커서를 원본 내용 위에 숨기고 확대 화면 위에 커서를 그림(`Zoomer`). 모니터 끝에 머무르던 동작(`offset`)은 보이는 영역 끝에서만 움직이는 `pan`으로 바뀜. 같은 작업의 코드 리뷰 반영: 시작 중 끄기 취소, 시스템이 스트림을 멈추면 확대 끄기, 캡처에 힌트·클릭 링·그린 커서가 찍히지 않음, 그린 커서를 잉크·스팟 위 창으로, `frozen`을 `direct` 하나로 합침.

- Windows 1.8.9 (2026-11-07): 맨 위·맨 아래에 붙는 가로 툴바(`Toolbar`가 직접 끌기를 처리, `Cfg.barEdge`), 가로일 때 설정 패널 4열(`SettingsPanel.wideColumns`), 툴바 위 모니터 끝에서 확대 화면 이동(`Zoomer.panFromEdge`). 툴팁이 함께 확대된다는 Windows 안내는 macOS에 해당 없음(힌트 창은 확대 영상에서 빠짐). 메모리: macOS 26에서 버튼 제목이 생겼다 사라지거나(`imagePosition` 전환) 컨트롤이 다시 배치될 때마다 AppKit이 KVO 객체를 약 20~30개씩 남김. 그래서 툴바 버튼은 아이콘과 제목을 한 이미지로 그리고, 설정 패널은 보일 때만 제약만 바꿔 재배치함(가로·세로 30회 전환 시 증가 0).

## 우선 권장 (효과 대비 위험 낮음)

### 1. 명령의 실행 코드가 단축키 목록과 툴바 목록에 이중 정의
- 위치: `src/HighPen/Controller.swift` `makeActions()`(33-50), `toolbarButtons()`(64-77)
- 같은 id→클로저(`self.togglePen()` 등) 매핑이 12개 기능에서 두 번 적혀 있다.
- 툴팁 문자열 `Lang.t("Monitor") + " (" + Lang.t("Cycle") + ")"`도 `Controller.swift:48`과 `SettingsPanel.swift:76`에 중복.
- 제안: `{id, run}` 표 하나를 두고 두 목록이 이를 참조.
- 주의: 지우개는 단축키(`eraserHotkey` — 두 번째 누르면 전체 지우기)와 버튼(`toggleEraser`)이 의도적으로 다르다.

### 2. 칠판 종류가 매직 넘버 0/1/2
- 위치: `ToolState.swift:9,20,24-25,30-31`, `InkView.swift:27-35`(크기 3 배열), `Controller.swift`의 `applyMode`(`t.board == 1 ? .white : …`, `["Board","WhiteBoard","BlackBoard"][t.board]`)
- 제안: `enum Board: Int { case screen, white, black }` — 배경색과 제목 키를 enum이 갖도록.

### 3. 반복되는 UI 조각과 색상 상수
- panelBg 배경 + 1pt 테두리 상자: `Popups.swift:14-17, 47-50`, `Hints.swift:15-18`, `SettingsPanel.swift:62-65`
- "인셋을 둔 라벨 상자" 레이아웃: `Hints.swift:20-30` ≈ `Popups.swift:51-62`
- 줄바꿈 라벨 생성: UpdateBox `wrap`, `SettingsPanel.swift:154-157`, `HotkeyEditor.swift:27-30, 58-59`, Hints
- 경고색 `rgb(0xFF9F0A)`: `BreakTimer.swift:93`, `HotkeyEditor.swift:96`, `SettingsPanel.swift:155`
- 빨강 `rgb(0xFF453A)`: `BreakTimer.swift:93`, `Controller.swift:77`
- 툴바 폭 84 / 28: `Toolbar.swift:41, 54, 85, 104`
- 색 개수 가정: `Settings.swift:20-25`의 `0...7`, `Controller.swift:52`의 8개 `digits` → `palette.count` 기준으로
- 제안: `Theme.swift`에 `bordered(_:)`, `padded(_:insets:)`, `wrapLabel(...)`, 이름 있는 색·크기 상수.

## 그 다음

### 4. 팝업 여닫기 방식이 제각각
- `AboutBox.toggle()`: 열려 있으면 닫음 / `UpdateBox.show()`: `orderFrontRegardless` / `HotkeyEditor`: `makeKeyAndOrderFront`
- `Toast`는 같은 함수 안에서 닫기 처리를 두 번 반복하고(`Popups.swift:63-67, 75-78`), `hide()`는 다른 팝업과 달리 `window`를 nil로 비우지 않는다.
- 제안: `isOpen` / `present` / `close`를 가진 작은 공용 팝업 기반.

### 5. `applyMode`가 모든 갱신을 떠안음 (유일한 구조 변경, 위험 중간)
- 위치: `Controller.swift:285-310`
- 노트 확정, 잉크 페이지·도구, 커서, 포커스, 클릭 통과, 배경, 줌, 툴바 강조 10개, 툴바 위치까지 한 함수에서 처리.
- `toggleSettings`, `toggleBreak`는 강조 하나 바꾸려고 이 전체를 호출한다.
- 제안: `applyTool()`과 `syncToolbar()`로 분리.
- 주의: 호출하는 쪽이 `placeBar()`, `endBubble` 같은 부수 효과에 기대고 있을 수 있으니 호출처별로 확인.

## 사소함

- **설정 패널 갱신 방식 불일치:** `togglePressure`, `toggleClicks`(`Controller.swift:197-198`)는 패널 전체를 다시 만들고(그러면서 `rebuild()`와 달리 hover 힌트를 먼저 숨기지 않음), 색 변경은 해당 스와치만 갱신한다. 해당 버튼만 갱신하도록 통일.
- **반복 타이머 설정 3회:** `BreakTimer.swift:76`, `Spot.swift:31`, `Zoomer.swift:56` — `repeatingTimer(_:_:)` 도우미.
- **화면 캡처 설정 중복:** `ScreenCapture.swift:11-17`과 `Zoomer.swift:36-44`가 shareable content 조회 → 디스플레이 찾기 → backing scale로 크기 설정을 각각 수행.

## 손댈 필요 없음

Stroke, InkView(실행 취소·지우기 로직), Zoomer의 가장자리 처리, Updater, Hotkey/Hotkeys, ToolState, Lang, Settings, Monitors, FocusKeeper, Clicks, Spot.
`make-icon.swift`의 `rgb` 중복은 독립 실행 스크립트라 의도된 것.
