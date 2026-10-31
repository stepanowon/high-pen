# 배포 진행 상황

마지막 업데이트: 2026-10-31

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
| 1.3.0 릴리스 | 완료 | `v1.3.0` 태그 → GitHub 릴리스 [HighPen v1.3.0](https://github.com/stepanowon/high-pen/releases/tag/v1.3.0) (`HighPen-Setup.exe`, `HighPen.exe`) |
| GitHub Actions 삭제 | 완료 | `.github/workflows/release.yml` 삭제 (main `df6f4ac`). 릴리스는 이제 직접 만든다 |
| README 정리 | 완료 | [#2](https://github.com/stepanowon/high-pen/pull/2) 병합: winget 설치 안내 추가, SignPath 설정 제거 |
| 1.4.0 기능 추가 | 완료 | [#9](https://github.com/stepanowon/high-pen/pull/9) 병합: 캡처(Ctrl+Alt+F), 클릭 표시(Ctrl+Alt+K), 모니터 연결/해제 자동 대응, 단축키 충돌 안내, 접기 화살표 버그 수정 |
| 1.4.0 릴리스 | 완료 | [#10](https://github.com/stepanowon/high-pen/pull/10) 병합(버전 변경). GitHub 릴리스 [HighPen v1.4.0](https://github.com/stepanowon/high-pen/releases/tag/v1.4.0) (`HighPen-Setup.exe`, `HighPen.exe`) |
| 1.7.3 기능 추가 | 완료 | [#29](https://github.com/stepanowon/high-pen/pull/29) 병합: 쉬는 시간 슬라이더를 5분 단위(5~120분)로 변경, 저장된 값도 가장 가까운 5분 단위로 맞춤. 버튼(10분·15분·1시간·1시간 30분)은 그대로 |
| 1.7.3 버전 변경 | 완료 | [#30](https://github.com/stepanowon/high-pen/pull/30)에서 버전 표기를 1.7.2로 되돌렸다가 [#31](https://github.com/stepanowon/high-pen/pull/31)에서 1.7.3으로 올림 (main `39a0232`) |
| 1.7.3 릴리스 | 완료 | GitHub 릴리스 [HighPen v1.7.3](https://github.com/stepanowon/high-pen/releases/tag/v1.7.3) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`), 한·일·영 변경 내용 포함 |
| 1.7.4 기능 추가 | 완료 | [#34](https://github.com/stepanowon/high-pen/pull/34) 병합: 전체 지우기를 되돌리기 한 단계로 기록해 지운 필기와 말풍선을 함께 되살림. 전체 지우기 후에도 이전 되돌리기 기록 유지. macOS 앱은 바꾸지 않음 |
| 1.7.4 버전 변경 | 완료 | [#35](https://github.com/stepanowon/high-pen/pull/35) 병합 (main `677a9fb`) |
| 1.7.4 릴리스 | 완료 | GitHub 릴리스 [HighPen v1.7.4](https://github.com/stepanowon/high-pen/releases/tag/v1.7.4) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`), 한·일·영 변경 내용 포함 |
| 실행 파일 배포 경로 변경 | 완료 | 보안 검토 후속 조치: `dist/*.exe`를 git에서 빼고 GitHub 릴리스에서만 배포. v1.7.4 릴리스에 `SHA256SUMS.txt` 추가(커밋돼 있던 exe와 릴리스 파일의 해시가 같음을 확인), README 다운로드 링크를 릴리스 주소로 변경, `checksums.ps1` 추가 |
| 1.8.0 기능 추가 | 완료 | 자동 업데이트: 시작할 때 GitHub 릴리스(`v` 태그만, macOS 릴리스 제외)에서 새 버전을 확인하고 업데이트 창에서 설치. 설치본은 새 `HighPen-Setup.exe /S /run`, 단독 exe는 자기 교체 후 재시작. `SHA256SUMS.txt`로 검증. Store(MSIX) 버전은 확인하지 않음. 설정 패널 **업데이트 확인**으로 끌 수 있음(1.8.1에서 없앰). 개인정보 처리방침과 README 갱신 |
| 1.8.0 릴리스 | 완료 | GitHub 릴리스 [HighPen v1.8.0](https://github.com/stepanowon/high-pen/releases/tag/v1.8.0) (`HighPen-Setup.exe`, `HighPen.exe`, `HighPen.msix`, `SHA256SUMS.txt`). 1.7.4 이하 사용자는 자동 업데이트 기능이 없어 이번 한 번은 직접 받아야 함 |
| 1.8.1 기능 추가: Store로 업데이트 안내 | 완료 | GitHub 배포본은 새 버전을 GitHub에서 내려받지 않고 업데이트 창의 **Microsoft Store에서 받기**로 Store 페이지(`ms-windows-store://pdp/?ProductId=9PDG1QN5QSL3`)를 열어 서명된 Store 패키지를 설치하게 바꿈. 1.8.0이 남기는 `/waitpid` 재시작과 `.old` 정리는 호환을 위해 유지. 업데이트 확인 켜기/끄기 설정을 없애고 시작할 때 항상 확인하며, 설정 패널에 **업데이트 확인** 버튼을 둬서 직접 확인(새 버전이면 업데이트 창, 아니면 "최신 버전입니다" 또는 실패 알림). 버전 1.8.1 |
| 1.8.1 GitHub 릴리스 | **할 일** | **Store에 1.8.1이 게시된 뒤에** 만든다. `dist`의 1.8.1 파일(`HighPen-Setup.exe` `6ce195a7…`, `HighPen.exe` `b72a328f…`, `HighPen.msix` `c16b4f86…`)과 `SHA256SUMS.txt`를 올린다(1.8.0이 이 파일들로 스스로 업데이트함). 릴리스 후 한·영·일 Windows README의 다운로드 링크와 버전 표기를 v1.8.1로 바꾼다 |

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
| 1.7.4 제출 | 완료 | 1.7.4.0 패키지가 Store에 게시됨(2026-10-31 확인). 현재 Store 버전 |
| 1.8.0 MSIX | 완료 | `dist/HighPen.msix` (1.8.0.0) 빌드. `makeappx.exe`는 NuGet `Microsoft.Windows.SDK.BuildTools` 10.0.28000.2957을 임시로 받아 사용 |
| 1.8.0 제출 | 불필요 | 1.8.0의 변경(업데이트 확인)은 Store 버전에서 동작하지 않아 Store 사용자에게 바뀌는 것이 없음. Store로 업데이트를 안내하는 다음 버전을 제출할 때 함께 올라감 |
| 1.8.1 MSIX | 완료 | `dist/HighPen.msix` (1.8.1.0) 빌드. `HighPen-Setup.exe`는 msix와 같은 `HighPen.exe`로 빌드 |
| 1.8.1 제출 | **할 일** | Partner Center에서 새 제출로 1.8.1.0 패키지 업로드. Store 사용자에게 보이는 변경은 없음(업데이트 확인·Store 안내는 GitHub 배포본에서만 동작). 게시되면 GitHub 릴리스 진행 |

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
