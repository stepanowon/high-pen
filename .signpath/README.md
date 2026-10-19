# 코드 서명 설정 (SignPath Foundation)

HighPen 실행 파일은 [SignPath Foundation](https://signpath.org)의 무료 오픈소스 코드 서명으로 서명합니다.
서명은 GitHub Actions(`.github/workflows/release.yml`)에서만 이루어지고, 로컬에서 `build.ps1`로 만든 파일은 서명되지 않습니다.

## 1. SignPath Foundation 신청

1. https://signpath.org/apply 에서 프로젝트를 신청합니다.
   - 저장소: https://github.com/stepanowon/high-pen
   - 라이선스: MIT
2. README의 **코드 서명 정책** 절이 신청 조건(서명 제공 문구, 팀 역할, 개인정보 정책)을 담고 있습니다.
   - Privacy Policy URL: https://github.com/stepanowon/high-pen/blob/main/PRIVACY.md
3. 승인되면 SignPath 조직(organization)과 프로젝트가 만들어집니다.

## 2. SignPath 프로젝트 설정

SignPath 웹 화면에서 다음을 설정합니다.

| 항목 | 값 |
|---|---|
| 프로젝트 slug | `high-pen` (다르면 저장소 변수 `SIGNPATH_PROJECT_SLUG`로 지정) |
| 서명 정책 slug | `release-signing` (다르면 저장소 변수 `SIGNPATH_SIGNING_POLICY_SLUG`로 지정) |
| Trusted build system | GitHub.com, 저장소 `stepanowon/high-pen` 연결 |
| 아티팩트 구성 `app` | [`artifact-configurations/app.xml`](artifact-configurations/app.xml) 내용 |
| 아티팩트 구성 `setup` | [`artifact-configurations/setup.xml`](artifact-configurations/setup.xml) 내용 |

아티팩트 구성은 두 개가 필요합니다. 설치 파일이 `HighPen.exe`를 내부에 담고 있어서, 앱을 먼저 서명한 뒤 그 앱으로 설치 파일을 빌드하고 다시 서명하기 때문입니다.

## 3. GitHub 저장소 설정

저장소의 **Settings → Secrets and variables → Actions**에서:

| 종류 | 이름 | 값 |
|---|---|---|
| Secret | `SIGNPATH_API_TOKEN` | SignPath에서 발급한 CI 사용자 API 토큰 |
| Variable | `SIGNPATH_ORGANIZATION_ID` | SignPath 조직 ID |

`SIGNPATH_ORGANIZATION_ID`가 없으면 워크플로는 서명 단계를 건너뛰고 서명 없이 빌드만 합니다.

## 4. 릴리스

1. `src/HighPen.cs`의 `AppVersion`과 `src/Setup.cs`의 `Version`을 올리고 커밋합니다.
2. 같은 버전으로 태그를 푸시합니다.
   ```
   git tag v1.3.0
   git push origin v1.3.0
   ```
3. 워크플로가 빌드 → 앱 서명 → 설치 파일 빌드 → 설치 파일 서명 순서로 진행합니다. 서명 정책에 수동 승인이 있으면 SignPath에서 요청을 승인해야 다음 단계로 넘어갑니다(최대 1시간 대기).
4. 끝나면 GitHub Releases에 `HighPen-Setup.exe`와 `HighPen.exe`가 올라갑니다.

태그와 `AppVersion`이 다르면 워크플로가 실패합니다.
