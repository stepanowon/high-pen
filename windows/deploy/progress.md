# 배포 진행 상황

마지막 업데이트: 2026-11-07

## 목표

코드 서명 없이, 설치할 때 Windows SmartScreen 경고("Windows의 PC 보호")가 뜨지 않도록 배포한다.

- **Microsoft Store**: MSIX 패키지를 Store가 서명한다. 클릭 한 번 설치, 자동 업데이트, 스마트 앱 컨트롤과도 호환된다.
- **winget**: Store 앱은 winget `msstore` 원본에 자동으로 들어가므로 `winget install 9PDG1QN5QSL3`로 설치한다. winget-pkgs 별도 등록은 취소했다(2026-10-21).
- 설치 파일은 사용자별 설치(`%LOCALAPPDATA%\Programs\HighPen`, HKCU)라서 UAC 창은 뜨지 않는다.
- 웹에서 직접 받은 exe는 앞으로도 SmartScreen 경고가 뜬다.

## 진행 상황

### 공통

| 단계 | 상태 | 내용 |
| --- | --- | --- |
| 1.3.0 릴리스 | 완료 | `v1.3.0` 태그 → GitHub 릴리스 HighPen v1.3.0(릴리스 삭제됨) (`HighPen-Setup.exe`, `HighPen.exe`) |
| GitHub Actions 삭제 | 완료 | `.github/workflows/release.yml` 삭제 (main `df6f4ac`). 릴리스는 이제 직접 만든다 |
| README 정리 | 완료 | [#2](https://github.com/stepanowon/high-pen/pull/2) 병합: winget 설치 안내 추가, SignPath 설정 제거 |
| 1.4.0 기능 추가 | 완료 | [#9](https://github.com/stepanowon/high-pen/pull/9) 병합: 캡처(Ctrl+Alt+F), 클릭 표시(Ctrl+Alt+K), 모니터 연결/해제 자동 대응, 단축키 충돌 안내, 접기 화살표 버그 수정 |
| 1.4.0 릴리스 | 완료 | [#10](https://github.com/stepanowon/high-pen/pull/10) 병합(버전 변경). GitHub 릴리스 HighPen v1.4.0(릴리스 삭제됨) (`HighPen-Setup.exe`, `HighPen.exe`) |
| 1.7.3 기능 추가 | 완료 | [#29](https://github.com/stepanowon/high-pen/pull/29) 병합: 쉬는 시간 슬라이더를 5분 단위(5~120분)로 변경, 저장된 값도 가장 가까운 5분 단위로 맞춤. 버튼(10분·15분·1시간·1시간 30분)은 그대로 |
| 1.7.3 버전 변경 | 완료 | [#30](https://github.com/stepanowon/high-pen/pull/30)에서 버전 표기를 1.7.2로 되돌렸다가 [#31](https://github.com/stepanowon/high-pen/pull/31)에서 1.7.3으로 올림 (main `39a0232`) |
| 1.7.3 릴리스 | 완료 | GitHub 릴리스 HighPen v1.7.3(릴리스 삭제됨) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`), 한·일·영 변경 내용 포함 |
| 1.7.4 기능 추가 | 완료 | [#34](https://github.com/stepanowon/high-pen/pull/34) 병합: 전체 지우기를 되돌리기 한 단계로 기록해 지운 필기와 말풍선을 함께 되살림. 전체 지우기 후에도 이전 되돌리기 기록 유지. macOS 앱은 바꾸지 않음 |
| 1.7.4 버전 변경 | 완료 | [#35](https://github.com/stepanowon/high-pen/pull/35) 병합 (main `677a9fb`) |
| 1.7.4 릴리스 | 완료 | GitHub 릴리스 HighPen v1.7.4(릴리스 삭제됨) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`), 한·일·영 변경 내용 포함 |
| 실행 파일 배포 경로 변경 | 완료 | 보안 검토 후속 조치: `dist/*.exe`를 git에서 빼고 GitHub 릴리스에서만 배포. v1.7.4 릴리스에 `SHA256SUMS.txt` 추가(커밋돼 있던 exe와 릴리스 파일의 해시가 같음을 확인), README 다운로드 링크를 릴리스 주소로 변경, `checksums.ps1` 추가 |
| 1.8.0 기능 추가 | 완료 | 자동 업데이트: 시작할 때 GitHub 릴리스(`v` 태그만, macOS 릴리스 제외)에서 새 버전을 확인하고 업데이트 창에서 설치. 설치본은 새 `HighPen-Setup.exe /S /run`, 단독 exe는 자기 교체 후 재시작. `SHA256SUMS.txt`로 검증. Store(MSIX) 버전은 확인하지 않음. 설정 패널 **업데이트 확인**으로 끌 수 있음(1.8.2에서 없앰). 개인정보 처리방침과 README 갱신 |
| 1.8.0 릴리스 | 완료 | GitHub 릴리스 HighPen v1.8.0(릴리스 삭제됨) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`, `SHA256SUMS.txt`). 1.7.4 이하 사용자는 자동 업데이트 기능이 없어 이번 한 번은 직접 받아야 함 |
| 1.8.2 기능 추가: Store로 업데이트 안내 | 완료 | GitHub 배포본은 새 버전을 GitHub에서 내려받지 않고 업데이트 창의 **Microsoft Store에서 받기**로 Store 페이지(`ms-windows-store://pdp/?ProductId=9PDG1QN5QSL3`)를 열어 서명된 Store 패키지를 설치하게 바꿈. 1.8.0이 남기는 `/waitpid` 재시작과 `.old` 정리는 호환을 위해 유지. 업데이트 확인 켜기/끄기 설정을 없애고 시작할 때 항상 확인하며, 설정 패널에 **업데이트 확인** 버튼을 둬서 직접 확인(새 버전이면 업데이트 창, 아니면 "최신 버전입니다" 또는 실패 알림). 버전 1.8.2 (1.8.1은 Partner Center에 먼저 올린 패키지와 버전이 겹쳐 건너뜀) |
| 1.8.2 GitHub 릴리스 | 완료 | Store 게시 확인 후 GitHub 릴리스 HighPen v1.8.2(릴리스 삭제됨) (`HighPen-Setup.exe` `f0d496c9…`, `HighPen.exe` `b98c5e8d…`, `HighPen.msix` `9b189f60…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 1.8.0 코드와 1.8.2 코드 모두 v1.8.2를 새 버전으로 찾는 것 확인. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.2로 변경 |
| 1.8.3 기능 추가: Store 버전에도 업데이트 확인 버튼 | 완료 | 1.8.2까지 Store 버전에서는 **업데이트 확인** 버튼을 숨겼음. 1.8.3부터 Store 버전에도 보이고, 누르면 GitHub에 연결하지 않고 Store의 HighPen 전체 페이지를 열어 Store가 업데이트를 제공하게 함. GitHub 배포본의 동작은 그대로(업데이트 창의 Store 버튼은 간단 설치 창 `mode=mini`) |
| 1.8.3 GitHub 릴리스 | 완료 | Store 게시 확인 후 GitHub 릴리스 HighPen v1.8.3(릴리스 삭제됨) (`HighPen-Setup.exe` `dacf6c33…`, `HighPen.exe` `837ff692…`, `HighPen.msix` `16d26c5c…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.3으로 변경 |
| 1.8.4 기능 추가: 확대 화면 모서리 고정 | 완료 | 확대 중 포인터가 모니터의 가로·세로 끝에 닿은 뒤 중앙 쪽으로 돌아오면, 포인터가 화면 중앙을 지날 때까지 확대 화면이 그 끝에 머무름. 중앙을 지나면 포인터가 반대쪽 끝에 닿을 때 확대 화면도 함께 닿도록 이동. 멈춰 있는 동안에는 클릭이 보이는 내용이 아니라 실제 위치에 들어감(확대 잠금과 같음). macOS 앱은 바꾸지 않음 |
| 1.8.4 GitHub 릴리스 | 완료 | 사용자 요청으로 Store 게시 **전에** GitHub 릴리스 HighPen v1.8.4(릴리스 삭제됨) (`HighPen-Setup.exe` `177af7be…`, `HighPen.exe` `5b399be5…`, `HighPen.msix` `e36cb75b…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. Store 게시 전까지 GitHub 배포본은 업데이트 창에서 Store를 열어도 1.8.3만 받을 수 있음. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.4로 변경 |
| 1.8.5 버그 수정: 배율이 다른 모니터에서 확대 위치 어긋남 | 완료 | HighPen은 시스템 DPI 인식 프로세스라, 화면 배율이 시스템 DPI와 다른 모니터에서는 커서·모니터 좌표가 가상화되는데 Magnification API는 물리 픽셀로 해석해 확대 화면이 다른 영역(아래·오른쪽 또는 위·왼쪽)으로 치우쳤음. 확대 창 생성과 위치 계산만 스레드 DPI 컨텍스트를 Per-Monitor V2로 바꿔 물리 픽셀로 처리하고, 필기 오버레이에는 프로세스 좌표로 바꿔 전달. 확대 창이 흐릿하게 늘어나던 것도 사라짐. 테스트: 좌표 패턴을 확대해 화면 픽셀로 확인하는 하네스로 모니터 3대 100%, DISPLAY1·DISPLAY3 125/150/175%에서 통과(수정 전 코드는 150%에서 실패 재현). 시스템 DPI가 모니터보다 높은 경우는 이 PC에서 재현 불가 |
| 1.8.5 GitHub 릴리스 | 완료 | 1.8.5.0 Partner Center 제출 후 Store 게시 전에 GitHub 릴리스 HighPen v1.8.5(릴리스 삭제됨) (`HighPen-Setup.exe` `48449869…`, `HighPen.exe` `5a23f64a…`, `HighPen.msix` `007e1d75…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 받은 파일의 해시가 SHA256SUMS.txt와 같음 확인. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.5로 변경 |
| 1.8.6 개선: 메모리·CPU 사용 | 완료 | [#52](https://github.com/stepanowon/high-pen/pull/52) 병합(main `282e23d`). 되돌리기 기록을 페이지마다 최근 200단계로 제한, 공용 브러시 Freeze, 스냅 감시의 Process 해제, 확대 중 같은 뷰는 다시 처리하지 않음. 마우스 스폿을 끄면 포인터 추적 타이머도 멈춤(대기 중 5초 CPU 109~141ms → 31ms). 중복 코드 정리(팝업·셸 실행·모니터 정보). macOS 리팩토링 후보는 `macos/REFACTORING.md`에 기록만 함. 테스트: 실제 앱을 단축키·클릭·스크린샷으로 조작해 확인(되돌리기 205획/210회, 확대·고정 중 배율 변경, 언어 20회 전환 시 메모리·핸들, 팝업·토스트, 툴바 드래그 제한) |
| 1.8.6 GitHub 릴리스 | 완료 | 사용자 요청으로 Store 제출 **전에** GitHub 릴리스 HighPen v1.8.6(릴리스 삭제됨) (`HighPen-Setup.exe` `bfa6749e…`, `HighPen.exe` `6590ae5c…`, `HighPen.msix` `7dbd8ba6…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 받은 파일의 해시가 SHA256SUMS.txt와 같음 확인. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.6으로 변경 |
| 1.8.7 버그 수정: 1.8.6의 확대 중 클릭 위치와 화면 이동 문제 | 완료 | 1.8.6의 버그만 고친 버전. [#55](https://github.com/stepanowon/high-pen/pull/55) 병합(main `51377b9`). 실제 커서는 원본 내용 위에 숨기고 돋보기가 확대 이미지 안에 커서를 그려, 보이는 포인터 위치와 클릭 위치가 같아짐. 포인터가 보이는 영역의 끝에 닿을 때만 화면이 움직임. 설정바·팝업 위, 펜 모드, 쉬는 시간, 캡처, 시작 메뉴 같은 Windows 화면에서는 실제 커서를 화면 좌표에 표시. 펜 모드 밖의 펜·터치 입력, 실제 Win+Shift+S 오버레이, Alt+Tab·빠른 설정, 배율이 다른 모니터는 시험하지 못함 |
| 1.8.7 GitHub 릴리스 | 완료 | 사용자 요청으로 Store 게시 **전에** GitHub 릴리스 HighPen v1.8.7(릴리스 삭제됨) (`HighPen-Setup.exe` `0110364c…`, `HighPen.exe` `bb7d26b4…`, `HighPen.msix` `83ce0bc5…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. README 링크는 v1.8.6으로 남겨 뒀다가 1.8.8 때 함께 변경 |
| 1.8.8 버전 변경 | 완료 | [#56](https://github.com/stepanowon/high-pen/pull/56) 병합(main `a0b4a19`). 코드는 1.8.7과 같고 버전 문자열만 변경. 1.8.7.0 패키지를 Partner Center에 이미 올려서 번호를 다시 쓸 수 없었음 |
| 1.8.8 GitHub 릴리스 | 완료 | Store 게시 후(사용자 확인) GitHub 릴리스 HighPen v1.8.8(릴리스 삭제됨) (`HighPen-Setup.exe` `f72262c3…`, `HighPen.exe` `e34b9e7a…`, `HighPen.msix` `cbdfc3e3…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 공개 주소에서 받은 파일의 해시가 SHA256SUMS.txt와 같음 확인. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.8로 변경 |
| 1.8.9 기능: 가로 설정바 | 완료 | [#60](https://github.com/stepanowon/high-pen/pull/60) 병합(main `1d9dd28`). 끌면서 포인터를 작업 영역 맨 위나 맨 아래로 가져가면 설정바가 그 끝에 붙어 가로로 바뀜(아이콘만 표시, 높이 37px, 이름과 단축키는 툴팁). 가로일 때 설정 패널은 4열로 열림. 가로 폭이 작업 영역보다 긴 모니터에서는 세로 유지. 세로로 좌·우측 끝에 닿아 있으면 위아래로 가도 세로 유지. 가장 우측에서는 `<` 버튼과 HighPen의 위치가 바뀜. 확대 중 설정바 위에서 끝까지 가면 화면이 이동함. macOS는 보류. 테스트: 실제 앱을 입력 합성과 스크린샷으로 확인(끝 붙이기·떼기, 재시작, 모니터·언어 변경, 설정 패널, 접기, 확대 중 이동). 100%가 아닌 DPI, 작업표시줄이 없거나 위쪽·옆에 있는 경우는 시험하지 못함 |
| 1.8.9 GitHub 릴리스 | 완료 | 사용자 요청으로 Store 게시 **전에** GitHub 릴리스 [HighPen v1.8.9](https://github.com/stepanowon/high-pen/releases/tag/v1.8.9) (`HighPen-Setup.exe` `daf9170b…`, `HighPen.exe` `aecb32b6…`, `HighPen.msix` `70ef3489…`, `SHA256SUMS.txt`), 한·일·영 변경 내용 포함. 공개 주소에서 받은 파일의 해시가 SHA256SUMS.txt와 같음 확인. 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.9로 변경 |

### winget

| 단계 | 상태 | 내용 |
| --- | --- | --- |
| 매니페스트 작성 | 완료 | `StephenWon.HighPen` 1.3.0, 스키마 1.12.0, `winget validate` 통과 |
| winget-pkgs PR 제출 | 완료 | [microsoft/winget-pkgs#455634](https://github.com/microsoft/winget-pkgs/pull/455634) (fork `stepanowon/winget-pkgs`, 브랜치 `StephenWon.HighPen-1.3.0`) |
| CLA 서명 | 완료 | `license/cla` 통과 |
| 자동 검증 | 완료 | 01~10 모두 통과 (설치 파일 스캔, 설치 테스트 포함). 라벨 `Azure-Pipeline-Passed`, `Validation-Completed` |
| 등록 취소 | 완료 | Store 배포로 일원화하기로 해서 2026-10-21 09:54 UTC에 moderator 승인 전 PR을 닫음. fork 브랜치 `StephenWon.HighPen-1.3.0` 삭제. winget 설치는 `msstore` 원본(`winget install 9PDG1QN5QSL3`)으로 대신함 |

### Microsoft Store

| 단계 | 상태 | 내용 |
| --- | --- | --- |
| 개발자 계정 | 완료 | 게시자 이름 `StephenWon` |
| 앱 이름 예약 | 완료 | `HighPen` (MSIX 또는 PWA 앱) |
| MSIX 패키징 | 완료 | [#3](https://github.com/stepanowon/high-pen/pull/3) 병합. `packaging/build-msix.ps1` → `dist/HighPen.msix` (1.3.0.0) |
| Store 목록 로고 | 완료 | [#4](https://github.com/stepanowon/high-pen/pull/4) 병합. `packaging/StoreListing/HighPen-{71,150,300}.png` |
| 제출 (Submission 1) | 완료 | 가격 무료, 연령 등급 IARC 3+ / 전체 이용가, 한·영·일 Store 목록 |
| 인증 | 완료 | 인증 통과 |
| 게시 | 완료 | 첫 게시 2026-10-19 19:49 UTC (`FirstAvailableDate`). Store 페이지 열림. Partner Center "Store 현재 상태"(Submission 1)는 "currently available in the Microsoft Store" |
| 다운로드 활성화 | 완료 | 2026-10-21 10:31 UTC 확인: KR·US·JP 모두 `IsDownloadable`/`IsPurchaseEnabled` `true`. **원인:** 패키지 페이지의 Device family availability에서 **Windows 10/11 Desktop**이 체크되지 않아 게시되어도 어떤 PC에도 제공되지 않았음(Partner Center는 "Store에서 사용 가능"으로 표시, winget 설치 시 `0x803fb104`). 체크 후 제출해 해결 |
| 게시자 연락처 | 완료 | 1.4.0 게시와 함께 Store API의 `PublisherAddress`, `PublisherPhoneNumber`가 사무실 정보로 바뀜(2026-10-21 09:16 UTC 확인). 주소의 구 이름이 `Kangdon-gu`로 표시되어 Partner Center 법률 정보 철자 확인 필요 |
| Store 목록 검색어·짧은 설명 | **확인 필요** | 한·영·일 검색어 7개와 짧은 설명 작성. 영어·한국어 목록 저장 시 "목록을 저장할 수 없습니다" 오류 발생, 다시 저장 후 제출 필요 |
| README Store 안내 | 완료 | 한·영·일 README에 Store 배지 추가, Store 설치를 권장 방법으로 변경 |
| 1.4.0 MSIX | 완료 | `dist/HighPen.msix` (1.4.0.0) 빌드. `makeappx.exe`는 Windows SDK 미설치로 이전에 받은 SDK BuildTools를 사용 |
| 1.4.0 제출 (Submission 2) | 완료 | 2026-10-21 제출, 약 20분 만에 인증 통과 후 게시. 패키지 1.4.0.0, 검색어·짧은 설명·새 기능 설명(한·영·일) 포함. `runFullTrust` 사유에 마우스 훅·화면 캡처 용도 명시. Partner Center "Store 현재 상태"가 Submission 2로 바뀜 |
| 1.7.3 MSIX | 완료 | `dist/HighPen.msix` (1.7.3.0) 빌드. `makeappx.exe`는 `C:\Users\stepa\.claude\jobs\1e54521f\tmp\sdkbt\x\bin\10.0.28000.0\x64\makeappx.exe` 사용(임시 폴더라 지워질 수 있음) |
| 1.7.3 제출 | 건너뜀 | 따로 제출하지 않고 1.7.4에 내용을 합침 |
| 1.7.4 MSIX | 완료 | `dist/HighPen.msix` (1.7.4.0) 빌드. 1.7.3과 같은 `makeappx.exe` 사용. `HighPen-Setup.exe`는 msix와 같은 `HighPen.exe`로 빌드 |
| 1.7.4 제출 | 완료 | 1.7.4.0 패키지가 Store에 게시됨(2026-10-31 확인) |
| 1.8.0 MSIX | 완료 | `dist/HighPen.msix` (1.8.0.0) 빌드. `makeappx.exe`는 NuGet `Microsoft.Windows.SDK.BuildTools` 10.0.28000.2957을 임시로 받아 사용 |
| 1.8.0 제출 | 불필요 | 1.8.0의 변경(업데이트 확인)은 Store 버전에서 동작하지 않아 Store 사용자에게 바뀌는 것이 없음. Store로 업데이트를 안내하는 다음 버전을 제출할 때 함께 올라감 |
| 1.8.1 MSIX | 건너뜀 | 1.8.1.0을 두 번 빌드함(업데이트 확인 버튼 전 `22e051af…`, 후 `c16b4f86…`). 앞의 것이 Partner Center에 올라가 있어 같은 버전을 다시 올릴 수 없어 1.8.2로 올림 |
| 1.8.2 MSIX | 완료 | `dist/HighPen.msix` (1.8.2.0) 빌드. `HighPen-Setup.exe`는 msix와 같은 `HighPen.exe`로 빌드 |
| 1.8.2 제출 | 완료 | 1.8.2.0 패키지가 Store에 게시됨(2026-10-31 확인) |
| 1.8.3 MSIX | 완료 | `dist/HighPen.msix` (1.8.3.0) 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`837ff692…`) 확인 |
| 1.8.3 제출 | 완료 | 1.8.3.0 패키지가 Store에 게시됨(2026-10-31 확인). 현재 Store 버전. Store 사용자에게 보이는 변경: 설정 패널에 **업데이트 확인** 버튼(누르면 Store 페이지가 열림). Store 패키지 안에서 버튼 동작 실기 확인 필요 |
| 1.8.4 MSIX | 완료 | `dist/HighPen.msix` (1.8.4.0) `e36cb75b…` 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`5b399be5…`) 확인. `HighPen-Setup.exe` `177af7be…`는 같은 exe로 빌드 |
| 1.8.4 제출 | 완료 | 1.8.4.0 패키지를 Partner Center에 제출함(2026-11-01 확인). Store 게시 후 현재 Store 버전이 1.8.4가 됨 |
| 1.8.5 MSIX | 완료 | `dist/HighPen.msix` (1.8.5.0) `007e1d75…` 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`5a23f64a…`) 확인. `HighPen-Setup.exe` `48449869…`는 같은 exe로 빌드. `SHA256SUMS.txt` 작성 |
| 1.8.5 제출 | 완료 | 1.8.5.0 패키지를 Partner Center에 제출함(2026-11-02, 사용자 확인). 인증·게시 확인 필요 |
| 1.8.6 MSIX | 완료 | `dist/HighPen.msix` (1.8.6.0) `7dbd8ba6…` 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`6590ae5c…`) 확인. `HighPen-Setup.exe` `bfa6749e…`는 같은 exe로 빌드. `SHA256SUMS.txt` 작성 |
| 1.8.6 제출 | 대기 | 1.8.6.0 패키지를 Partner Center에 제출해야 함 |
| 1.8.7 제출 | 완료 | 1.8.6의 버그만 고친 1.8.7.0 패키지를 Partner Center에 올림(게시 여부는 기록 없음). 번호를 다시 쓸 수 없어 다음 제출은 1.8.8로 함 |
| 1.8.8 MSIX | 완료 | `dist/HighPen.msix` (1.8.8.0) `cbdfc3e3…` 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`e34b9e7a…`) 확인. `HighPen-Setup.exe` `f72262c3…`는 같은 exe로 빌드. `SHA256SUMS.txt` 작성 |
| 1.8.8 제출 | 완료 | 1.8.8.0 패키지가 Store에 게시됨(2026-11-07, 사용자 확인). 현재 Store 버전 |
| 1.8.9 MSIX | 완료 | `dist/HighPen.msix` (1.8.9.0) `70ef3489…` 빌드. MSIX 안의 `HighPen.exe`가 `dist/HighPen.exe`와 같음(`aecb32b6…`) 확인. `HighPen-Setup.exe` `daf9170b…`도 같은 exe를 포함함을 확인. `SHA256SUMS.txt` 작성 |
| 1.8.9 제출 | 대기 | 1.8.9.0 패키지를 Partner Center에 제출해야 함 |

## Store 정보

| 항목 | 값 |
| --- | --- |
| Store ID | `9PDG1QN5QSL3` |
| 웹 Store URL | https://apps.microsoft.com/detail/9PDG1QN5QSL3 |
| Package/Identity/Name | `StephenWon.HighPen` |
| Package/Identity/Publisher | `CN=58BB6EA5-E7A7-4A4F-9A0C-62261149B3A1` |
| PublisherDisplayName | `StephenWon` |
| Package Family Name | `StephenWon.HighPen_swdd7q8abfzng` |

## 다음 할 일

1. 다운로드 상태 확인 명령 (참고)
   ```powershell
   (Invoke-RestMethod "https://storeedgefd.dsx.mp.microsoft.com/v9.0/products/9PDG1QN5QSL3?market=KR&locale=ko-KR&deviceFamily=Windows.Desktop").Payload | Select-Object IsDownloadable, IsPurchaseEnabled, PublisherAddress, PublisherPhoneNumber
   ```
2. Store 버전 설치 확인: Store 앱 또는 `winget install 9PDG1QN5QSL3 --source msstore`로 설치한 뒤 `Get-AppxPackage -Name StephenWon.HighPen`에서 `Version` `1.4.0.0`, `SignatureKind` `Store` 확인
3. Partner Center 법률 정보의 주소 철자 확인 (Store에 `Kangdon-gu`로 표시됨)

## 다음 버전 배포 절차

Windows 앱 파일은 모두 `windows/` 아래에 있다. 아래 경로와 명령은 `windows` 디렉토리 기준이다.

1. `src/HighPen/Theme.cs`의 `AppVersion`과 `src/Setup.cs`의 `Version`을 같이 올린다.
2. 실행 파일은 git에 커밋하지 않는다(`.gitignore`). 릴리스에 올리는 파일이 모두 같은 `HighPen.exe`에서 나오도록 이 순서로 빌드한다.
   ```
   .\packaging\build-msix.ps1      # dist\HighPen.exe, dist\HighPen.msix
   .\build.ps1 -Target setup        # 방금 만든 HighPen.exe를 넣은 dist\HighPen-Setup.exe
   .\checksums.ps1                  # dist\SHA256SUMS.txt
   ```
   Windows SDK가 없으면 `build-msix.ps1`에 `-MakeAppx <makeappx.exe 경로>`를 붙인다.
3. 커밋·푸시한 뒤 릴리스를 만든다. 릴리스 노트에 `SHA256SUMS.txt` 내용을 붙여 둔다. 태그는 반드시 `v1.x.x` 형식이고 초안·시험판이 아니어야 한다. GitHub 배포본(1.8.0 이후)은 시작할 때 이 태그로 새 버전을 알아내고 Microsoft Store 페이지를 열어 설치하게 한다(`src/HighPen/Updater.cs`). **그래서 GitHub 릴리스는 같은 버전이 Store에 게시된 뒤에 만든다.** 먼저 만들면 Store에서 아직 이전 버전이 설치된다. 1.8.0만은 GitHub에서 `HighPen.exe`/`HighPen-Setup.exe`와 `SHA256SUMS.txt`를 받아 스스로 교체하므로, 이 파일 이름은 바꾸지 않는다(1.8.0 사용자가 다음 버전으로 한 번 넘어오는 경로).
   ```
   gh release create v1.x.x dist/HighPen-Setup.exe dist/HighPen.exe dist/HighPen.msix dist/SHA256SUMS.txt --title "HighPen v1.x.x" --generate-notes
   ```
4. 한·영·일 `README.md`의 다운로드 링크와 `SHA256SUMS.txt` 링크(`releases/download/v1.x.x/...`)를 새 버전으로 바꾼다.
5. Partner Center에서 **새 제출**의 패키지만 `dist\HighPen.msix`로 바꿔 제출한다 (자세한 내용: `packaging/STORE.md`). 패키지 페이지에서 **Windows 10/11 Desktop** 체크가 유지되는지 반드시 확인한다.
