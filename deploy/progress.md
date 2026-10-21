# 배포 진행 상황

마지막 업데이트: 2026-10-21

## 목표

코드 서명 없이, 설치할 때 Windows SmartScreen 경고("Windows의 PC 보호")가 뜨지 않도록 배포한다.

- **Microsoft Store**: MSIX 패키지를 Store가 서명한다. 클릭 한 번 설치, 자동 업데이트, 스마트 앱 컨트롤과도 호환된다.
- **winget**: 터미널에서 `winget install highpen`으로 경고 없이 설치한다.
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
| moderator 승인·병합 | **대기** | 1.3.0 PR 커뮤니티 moderator 검토 대기 (2026-10-21 07:31 UTC 확인: `REVIEW_REQUIRED`, 새 댓글·리뷰 없음) |
| 1.4.0 매니페스트 PR | **대기** | 1.3.0 PR 병합 후 제출. `InstallerSha256` `04E9AEAE8EEF77D6920816C934C11871F4408960ED4D92DB253268BEC46C82DD` |

### Microsoft Store

| 단계 | 상태 | 내용 |
| --- | --- | --- |
| 개발자 계정 | 완료 | 게시자 이름 `StephenWon` |
| 앱 이름 예약 | 완료 | `HighPen` (MSIX 또는 PWA 앱) |
| MSIX 패키징 | 완료 | [#3](https://github.com/stepanowon/high-pen/pull/3) 병합. `packaging/build-msix.ps1` → `dist/HighPen.msix` (1.3.0.0) |
| Store 목록 로고 | 완료 | [#4](https://github.com/stepanowon/high-pen/pull/4) 병합. `packaging/StoreListing/HighPen-{71,150,300}.png` |
| 제출 (Submission 1) | 완료 | 가격 무료, 연령 등급 IARC 3+ / 전체 이용가, 한·영·일 Store 목록 |
| 인증 | 완료 | 인증 통과 |
| 게시 | 완료 | 첫 게시 2026-10-19 19:49 UTC (`FirstAvailableDate`). Store 페이지 열림 |
| 다운로드 활성화 | **대기** | 2026-10-21 07:31 UTC(게시 후 약 36시간) 기준 Store API `IsDownloadable`/`IsPurchaseEnabled` 모두 `false`. KR·US·JP 시장 모두 같음. Store 앱에서 "이 제품은 현재 사용할 수 없습니다" |
| 게시자 연락처 | **Store 반영 대기** | Store 페이지 데이터에 판매자 연락처(주소·전화)가 공개되는 것을 확인. Partner Center 법률 정보에서 사무실 주소·전화로 변경했고 승인되어 법률 정보 페이지에 표시됨. Store API에는 아직 이전 정보가 나옴(2026-10-21 07:31 UTC) |
| Store 목록 검색어·짧은 설명 | **확인 필요** | 한·영·일 검색어 7개와 짧은 설명 작성. 영어·한국어 목록 저장 시 "목록을 저장할 수 없습니다" 오류 발생, 다시 저장 후 제출 필요 |
| README Store 안내 | 완료 | 한·영·일 README에 Store 배지 추가, Store 설치를 권장 방법으로 변경 |
| 1.4.0 MSIX | 완료 | `dist/HighPen.msix` (1.4.0.0) 빌드. `makeappx.exe`는 Windows SDK 미설치로 이전에 받은 SDK BuildTools를 사용 |
| 1.4.0 제출 (Submission 2) | **할 일** | Partner Center 새 제출에서 1.3.0.0 패키지를 1.4.0.0으로 교체, 검색어·짧은 설명 수정도 함께 제출 |

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

1. Store 다운로드 활성화 확인. 게시 후 48시간(2026-10-21 19:49 UTC)이 지나도 `false`면 Partner Center 고객 지원팀에 문의 (게시자 연락처가 아직 이전 정보로 공개되는 것도 함께 문의)
   ```powershell
   (Invoke-RestMethod "https://storeedgefd.dsx.mp.microsoft.com/v9.0/products/9PDG1QN5QSL3?market=KR&locale=ko-KR&deviceFamily=Windows.Desktop").Payload | Select-Object IsDownloadable, IsPurchaseEnabled, PublisherAddress, PublisherPhoneNumber
   ```
2. Partner Center에서 1.4.0 제출(Submission 2): 패키지를 `dist/HighPen.msix`(1.4.0.0)로 교체하고 1.3.0.0 패키지 제거, Store 목록 검색어·짧은 설명 저장, Store에 제출
3. 활성화 후 Store 버전 설치 확인: Store 앱에서 설치, `winget install 9PDG1QN5QSL3`
4. 게시 후 위 명령으로 `PublisherAddress`, `PublisherPhoneNumber`가 사무실 정보로 바뀌었는지 확인
5. winget PR #455634 moderator 승인 대기. 질문 댓글이 달리면 답변
6. 1.3.0 병합 후 `winget install highpen` 확인, 이어서 1.4.0 매니페스트 제출
   ```
   wingetcreate update StephenWon.HighPen -v 1.4.0 -u https://github.com/stepanowon/high-pen/releases/download/v1.4.0/HighPen-Setup.exe --submit
   ```

## winget 매니페스트 요약

경로: `manifests/s/StephenWon/HighPen/1.3.0/` (파일 4개: version, installer, locale.en-US, locale.ko-KR)

| 항목 | 값 |
| --- | --- |
| PackageIdentifier | `StephenWon.HighPen` |
| Moniker | `highpen` |
| InstallerType / Scope | `exe` / `user` |
| 조용한 설치 | `/S` |
| InstallerUrl | `https://github.com/stepanowon/high-pen/releases/download/v1.3.0/HighPen-Setup.exe` |
| InstallerSha256 | `9C10F437B7F13F87377CB5202C4E166E4D4849BE7B2CDACD52BF8506C450A5A8` |
| ARP 항목 | DisplayName `HighPen`, Publisher `HighPen`, DisplayVersion `1.3.0` |

## 다음 버전 배포 절차

1. `src/HighPen.cs`의 `AppVersion`과 `src/Setup.cs`의 `Version`을 같이 올린다.
2. `.\build.ps1`로 `dist\HighPen.exe`, `dist\HighPen-Setup.exe`를 빌드한다.
3. 커밋·푸시한 뒤 릴리스를 만든다.
   ```
   gh release create v1.x.x dist/HighPen-Setup.exe dist/HighPen.exe --title "HighPen v1.x.x" --generate-notes
   ```
4. winget 매니페스트를 갱신해 제출한다 (`winget install wingetcreate`로 설치).
   ```
   wingetcreate update StephenWon.HighPen -v 1.x.x -u https://github.com/stepanowon/high-pen/releases/download/v1.x.x/HighPen-Setup.exe --submit
   ```
5. Store 패키지를 만들고 Partner Center에서 **새 제출**의 패키지만 바꿔 제출한다 (자세한 내용: `packaging/STORE.md`).
   ```
   .\packaging\build-msix.ps1
   ```
   Windows SDK가 없으면 `-MakeAppx <makeappx.exe 경로>`로 지정한다. 스크립트가 `dist\HighPen.exe`를 다시 빌드하므로, 소스가 그대로면 `git checkout -- dist/HighPen.exe`로 커밋된 파일을 되돌린다.
