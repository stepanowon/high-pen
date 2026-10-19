# 배포 진행 상황

마지막 업데이트: 2026-10-19

## 목표

코드 서명 없이, 설치할 때 Windows SmartScreen 경고("Windows의 PC 보호")가 뜨지 않도록 **winget**으로 배포한다.

- 설치 파일은 사용자별 설치(`%LOCALAPPDATA%\Programs\HighPen`, HKCU)라서 UAC 창은 뜨지 않는다. 문제는 SmartScreen 경고뿐이다.
- 웹에서 직접 받은 exe는 앞으로도 SmartScreen 경고가 뜬다. winget으로 설치할 때만 경고가 없다.

## 진행 상황

| 단계 | 상태 | 내용 |
| --- | --- | --- |
| 1.3.0 릴리스 | 완료 | `v1.3.0` 태그 → GitHub 릴리스 [HighPen v1.3.0](https://github.com/stepanowon/high-pen/releases/tag/v1.3.0) (`HighPen-Setup.exe`, `HighPen.exe`) |
| GitHub Actions 삭제 | 완료 | `.github/workflows/release.yml` 삭제 (main `df6f4ac`). 릴리스는 이제 직접 만든다 |
| winget 매니페스트 작성 | 완료 | `StephenWon.HighPen` 1.3.0, 스키마 1.12.0, `winget validate` 통과 |
| winget-pkgs PR 제출 | 완료 | [microsoft/winget-pkgs#455634](https://github.com/microsoft/winget-pkgs/pull/455634) (fork `stepanowon/winget-pkgs`, 브랜치 `StephenWon.HighPen-1.3.0`) |
| CLA 서명 | 완료 | `license/cla` 통과 |
| winget 자동 검증 | **진행 중** | 01~06 통과, 07 설치 파일 스캔 / 08 설치 테스트 / 09 메타데이터 / 10 완료 대기 |
| moderator 검토·병합 | 대기 | 첫 등록 패키지라 사람 검토가 있다 |
| README 정리 | PR 열림 | [stepanowon/high-pen#2](https://github.com/stepanowon/high-pen/pull/2): winget 설치 안내 추가, SignPath 설정 제거 |

## 다음 할 일

1. winget PR #455634의 검증 결과 확인
   - 통과: `Azure-Pipeline-Passed` 라벨 → moderator 검토 대기
   - 실패: `Validation-…-Error` 라벨 (서명 없는 exe라 `Validation-Defender-Error` 등이 나올 수 있음) → 원인 확인 후 매니페스트 수정
2. moderator 질문 댓글이 달리면 답변
3. winget PR이 병합된 **뒤에** high-pen PR #2 병합 (그 전에는 `winget install highpen`이 동작하지 않음)
4. 병합 후 확인: `winget search highpen`, `winget install highpen`

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
