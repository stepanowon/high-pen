# HighPen for macOS

- **한국어:** 지금 보고 있는 문서입니다.
- **English:** [Read this document in English.](README.en.md)
- **日本語:** [日本語版のドキュメントはこちらです。](README.ja.md)

[← HighPen 소개로 돌아가기](../README.md)

비대면 강의용 펜 앱의 macOS 버전입니다. macOS 14 (Sonoma) 이상, Apple 실리콘과 Intel Mac을 모두 지원합니다.

## 다운로드

**[HighPen-1.1.0.dmg 받기](https://github.com/stepanowon/high-pen/releases/download/macos-v1.1.0/HighPen-1.1.0.dmg)** (사전 릴리스 [macos-v1.1.0](https://github.com/stepanowon/high-pen/releases/tag/macos-v1.1.0))

DMG를 열고 HighPen을 Applications 폴더로 끌어다 놓으면 설치됩니다. 처음 열 때 "확인되지 않은 개발자" 경고로 막히면 [DMG 패키지](#dmg-패키지)에 있는 방법으로 엽니다.

> 사전 릴리스입니다. 아직 App Store 배포와 Apple 공증은 없습니다.

## 빌드

Xcode 없이 Command Line Tools만 있으면 됩니다 (`xcode-select --install`).

```sh
cd macos
./build.sh          # dist/HighPen.app 생성 (universal, ad-hoc 서명)
./build.sh test     # 빌드 후 자체 점검 실행
open dist/HighPen.app
```

버전은 `build.sh`의 `VERSION` 한 곳에서 관리합니다.

## DMG 패키지

```sh
./build.sh dmg      # dist/HighPen-<버전>.dmg 생성
```

DMG를 열고 HighPen을 Applications 폴더로 끌어다 놓으면 설치됩니다.

아직 Apple 개발자 인증서 서명과 공증(notarization)을 하지 않아서, 인터넷으로 받은 DMG의 앱을 처음 열면 "확인되지 않은 개발자" 경고와 함께 실행이 막힙니다. 다음 중 한 가지 방법으로 엽니다.

- 시스템 설정 > 개인정보 보호 및 보안 아래쪽의 **확인 없이 열기**를 누릅니다.
- 터미널에서 `xattr -dr com.apple.quarantine /Applications/HighPen.app`을 실행합니다.

경고 없이 배포하려면 Apple Developer Program 가입 후 Developer ID 서명과 공증이 필요합니다.

## 기능

| 기능 | 단축키 | 설명 |
|---|---|---|
| 마우스 스팟 | ⌃⌥S | 포인터를 따라다니는 반투명 원 |
| 펜 | ⌃⌥P | 화면 위에 필기. 펜 태블릿 필압 반영 (⌃⌥R로 켜기/끄기) |
| 형광펜 | ⌃⌥L | 펜 획 아래에 반투명으로 그려짐 |
| 지우개 | ⌃⌥E | 획 단위로 지움. 지우개 상태에서 한 번 더 누르면 전체 삭제 |
| 칠판 | ⌃⌥B | 흰 칠판 → 검은 칠판 → 끄기. 화면 필기와 따로 보관 |
| 되돌리기 | ⌃⌥Z | 획 하나, 또는 지우개로 한 번 문지른 것 전체 |
| 전체 지우기 | ⌃⌥C | 현재 페이지 지우기 |
| 말풍선 | ⌃⌥T | 클릭한 위치에 글 상자. Enter 확정, Shift+Enter 줄바꿈, Esc 취소. 전체 지우기로만 삭제 |
| 확대 | ⌃⌥X | 1.5x / 2x / 2.5x 실시간 확대. 펜을 켜면 화면이 고정되어 확대된 화면 위에 필기 |
| 캡처 | ⌃⌥F | 화면과 필기를 `~/Pictures/HighPen`에 PNG로 저장하고 클립보드에 복사 |
| 설정 | ⌃⌥D | 색상, 두께, 스팟, 확대 배율, 모니터, 언어(한·일·영) |
| 접기/펴기 | ⌃⌥H | 툴바 접기 |
| 모니터 순환 | ⌃⌥M | 다중 모니터에서 작동 모니터 변경 |
| 펜 색상 | ⌃⌥1 ~ ⌃⌥8 | 빨강, 주황, 노랑, 초록, 파랑, 보라, 검정, 흰색 (형광펜 사용 중이면 형광펜 색상) |
| 정보 | | 버전, 저작자, 연락처, 라이선스 |
| 종료 | ⌃⌥Q | |

### 단축키 바꾸기

설정 > **단축키 설정**에서 항목을 누른 뒤 새 조합을 누르면 바뀝니다. Esc는 취소, Delete는 단축키 없애기, **기본값으로**는 전체 되돌리기입니다. ⌃, ⌥, ⌘ 중 하나와 함께 눌러야 하며 F1~F20은 단독으로 쓸 수 있습니다. 이미 다른 항목에 쓰는 조합이나 다른 앱이 사용 중인 조합은 안내가 나옵니다.

툴바는 머리 부분을 끌어서 옮길 수 있고, 위치와 설정은 자동으로 저장됩니다. Dock 아이콘을 누르면 접힌 툴바가 다시 펼쳐집니다. 툴바와 설정 항목 위에 포인터를 올리면 이름과 단축키가 보입니다.

펜·형광펜·지우개를 켜면 포인터가 해당 도구 모양으로 바뀝니다. macOS는 활성 앱만 포인터 모양을 바꿀 수 있어서, 펜 모드(와 단축키 설정 창) 동안은 HighPen이 활성 앱이 되고 끝나면 원래 앱(예: 슬라이드쇼)으로 돌아갑니다. 따라서 펜 모드 중에는 키보드 입력(슬라이드 넘기기 등)이 원래 앱으로 가지 않습니다. HighPen 단축키는 언제나 동작합니다.

## 권한

확대와 캡처에는 **화면 기록** 권한이 필요합니다. 처음 사용할 때 안내가 나오면 시스템 설정 > 개인정보 보호 및 보안 > 화면 및 시스템 오디오 녹음에서 HighPen을 켠 뒤, **HighPen을 종료하고 다시 실행**하세요 (macOS는 다시 실행해야 권한을 적용합니다).

다시 빌드해도 권한이 유지되도록 번들 ID(`com.stepanowon.HighPen`) 기준으로 서명합니다. 이전 빌드에서 켠 권한이 동작하지 않으면 `tccutil reset ScreenCapture com.stepanowon.HighPen`으로 초기화한 뒤 다시 켜세요.

## Windows 버전과의 차이

- 단축키는 `Ctrl+Alt` 대신 `⌃⌥`(Control+Option)를 씁니다. 펜 색상은 다른 앱과 겹치지 않도록 `⌃⌥1~8`로 바꿨습니다.
- 아직 없는 기능: 말풍선, 클릭 표시.
- 확대 중 포인터를 모니터 안에 가두지 않습니다 (macOS에 해당 기능이 없음).

## 구조

| 경로 | 내용 |
|---|---|
| `src/HighPen.swift` | 앱 전체 (AppKit, ScreenCaptureKit, Carbon 단축키) |
| `src/make-icon.swift` | 앱 아이콘 생성 (Windows 아이콘과 같은 디자인을 macOS 아이콘 규격에 맞춰 크기별로 그림) |
| `build.sh` | `swiftc`로 arm64·x86_64 빌드 → `lipo` → `.app` 번들 생성, 아이콘 생성, ad-hoc 서명, DMG 패키징 |
