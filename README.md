# HighPen

- **한국어:** 지금 보고 있는 문서입니다.
- **English:** [Read this document in English.](README.en.md)
- **日本語:** [日本語版のドキュメントはこちらです。](README.ja.md)

비대면 강의용 펜 앱입니다. 화면 위에 바로 필기하고, 마우스 포인터를 스팟으로 강조하고, 화면을 확대하고, 칠판을 띄울 수 있습니다.

![HighPen 설정바와 마우스 스팟](screen/전체화면1.png)

## 플랫폼

| 플랫폼 | 상태 | 문서 |
|---|---|---|
| Windows 10/11 | 배포 중 (Microsoft Store, winget, exe) | [설치와 사용 방법](windows/README.md) |
| macOS 14 이상 | 사전 릴리스 (DMG) | [빌드와 사용 방법](macos/README.md) |

### Windows

[<img src="https://get.microsoft.com/images/ko%20dark.svg" width="200" alt="Microsoft Store에서 받기"/>](https://apps.microsoft.com/detail/9PDG1QN5QSL3?mode=direct)

Microsoft Store에서 설치하는 것을 권장합니다. winget, 설치 없이 실행하는 exe, 설치 파일 등 다른 방법과 기능 설명은 [Windows 문서](windows/README.md)를 참고하세요.

### macOS

**[HighPen-1.1.0.dmg 받기](https://github.com/stepanowon/high-pen/releases/download/macos-v1.1.0/HighPen-1.1.0.dmg)** (사전 릴리스 [macos-v1.1.0](https://github.com/stepanowon/high-pen/releases/tag/macos-v1.1.0))

macOS 14 (Sonoma) 이상, Apple 실리콘과 Intel Mac을 지원합니다. DMG를 열고 HighPen을 Applications 폴더로 끌어다 놓으면 설치됩니다. 아직 Apple 공증을 받지 않아서, **처음 열기 전에** 터미널에서 다음 명령을 실행해야 경고 없이 열립니다. (명령 없이 열었다가 경고 창에서 **휴지통으로 이동**을 누르면 앱이 삭제됩니다.)

```sh
xattr -dr com.apple.quarantine /Applications/HighPen.app
```

빌드 방법, 기능과 단축키, 권한 설정은 [macOS 문서](macos/README.md)를 참고하세요.

## 저장소 구조

| 경로 | 내용 |
|---|---|
| `windows/` | Windows 앱 (소스, 빌드 스크립트, 실행 파일, Store 패키징, 배포 기록) |
| `macos/` | macOS 앱 (소스, 빌드·DMG 패키징 스크립트, 문서) |
| `screen/` | 문서용 스크린샷과 소개 영상 |
| `PRIVACY.md` | 개인정보 처리방침 |

## 개인정보

이 프로그램은 사용자나 설치·운영하는 사람이 명시적으로 요청하지 않는 한 어떤 정보도 다른 네트워크 시스템으로 전송하지 않습니다. 자세한 내용은 [개인정보 처리방침](PRIVACY.md#한국어)을 참고하세요.

## 라이선스

[MIT License](LICENSE)로 배포됩니다. 상업적 용도를 포함해 자유롭게 사용, 수정, 배포할 수 있으며, 배포 시 저작권 및 라이선스 문구를 포함해야 합니다.
