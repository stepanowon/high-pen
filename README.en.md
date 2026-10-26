# HighPen

- **한국어:** [한국어로 된 문서는 여기를 보세요.](README.md)
- **English:** You are reading this document.
- **日本語:** [日本語版のドキュメントはこちらです。](README.ja.md)

HighPen is a pen app for online lectures. You can write directly on the screen, highlight the mouse pointer with a spotlight, zoom in on the screen, and bring up a whiteboard.

![HighPen toolbar and mouse spot](screen/전체화면1.png)

## Platforms

| Platform | Status | Docs |
|---|---|---|
| Windows 10/11 | Available (Microsoft Store, winget, exe) | [Installation and usage](windows/README.en.md) |
| macOS 14+ | Available (DMG, not on the App Store) | [Build and usage](macos/README.en.md) |

### Windows

[<img src="https://get.microsoft.com/images/en-us%20dark.svg" width="200" alt="Get it from Microsoft"/>](https://apps.microsoft.com/detail/9PDG1QN5QSL3?mode=direct)

Installing from the Microsoft Store is recommended. For other options (winget, a portable exe, the installer) and a description of every feature, see the [Windows docs](windows/README.en.md).

### macOS

**[Download HighPen-1.3.0.dmg](https://github.com/stepanowon/high-pen/releases/download/macos-v1.3.0/HighPen-1.3.0.dmg)** (release [macos-v1.3.0](https://github.com/stepanowon/high-pen/releases/tag/macos-v1.3.0))

Runs on macOS 14 (Sonoma) or later, on Apple silicon and Intel Macs. Open the DMG and drag HighPen onto the Applications folder. HighPen is not notarized by Apple yet, so **before opening it the first time**, run this in Terminal to open it without a warning. (If you open it without the command and click **Move to Trash** in the warning, the app is deleted.)

```sh
xattr -dr com.apple.quarantine /Applications/HighPen.app
```

For building, features and shortcuts, and permissions, see the [macOS docs](macos/README.en.md).

## Repository layout

| Path | Contents |
|---|---|
| `windows/` | The Windows app (source, build scripts, executables, Store packaging, release notes) |
| `macos/` | The macOS app (source, build and DMG packaging script, docs) |
| `screen/` | Screenshots and the trailer video used in the docs |
| `PRIVACY.md` | Privacy policy |

## Privacy

This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it. See the [privacy policy](PRIVACY.md#english) for details.

## License

Released under the [MIT License](LICENSE). You may use, modify and distribute it freely, including for commercial purposes, as long as the copyright and license notice are included.
