# 배포 진행 상황

마지막 업데이트: 2026-10-21

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
2. `.\build.ps1`로 `dist\HighPen.exe`, `dist\HighPen-Setup.exe`를 빌드한다.
3. 커밋·푸시한 뒤 릴리스를 만든다.
   ```
   gh release create v1.x.x dist/HighPen-Setup.exe dist/HighPen.exe --title "HighPen v1.x.x" --generate-notes
   ```
4. Store 패키지를 만들고 Partner Center에서 **새 제출**의 패키지만 바꿔 제출한다 (자세한 내용: `packaging/STORE.md`). 패키지 페이지에서 **Windows 10/11 Desktop** 체크가 유지되는지 반드시 확인한다.
   ```
   .\packaging\build-msix.ps1
   ```
   Windows SDK가 없으면 `-MakeAppx <makeappx.exe 경로>`로 지정한다. 스크립트가 `dist\HighPen.exe`를 다시 빌드하므로, 소스가 그대로면 `git checkout -- dist/HighPen.exe`로 커밋된 파일을 되돌린다.
