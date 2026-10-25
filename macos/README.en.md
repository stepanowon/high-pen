# HighPen for macOS

- **한국어:** [한국어로 된 문서는 여기를 보세요.](README.md)
- **English:** You are reading this document.
- **日本語:** [日本語版のドキュメントはこちらです。](README.ja.md)

[← Back to the HighPen overview](../README.en.md)

The macOS version of the pen app for online lectures. It runs on macOS 14 (Sonoma) or later, on both Apple silicon and Intel Macs.

## Download

**[Download HighPen-1.1.0.dmg](https://github.com/stepanowon/high-pen/releases/download/macos-v1.1.0/HighPen-1.1.0.dmg)** (pre-release [macos-v1.1.0](https://github.com/stepanowon/high-pen/releases/tag/macos-v1.1.0))

1. Open the DMG and drag HighPen onto the Applications folder.
2. **Before opening it the first time**, run this in Terminal. HighPen then opens without any warning.

```sh
xattr -dr com.apple.quarantine /Applications/HighPen.app
```

HighPen is not notarized by Apple yet, so without this command macOS warns that it "cannot verify 'HighPen' is free of malware". Click **Done**, not **Move to Trash** (that deletes the app). Then click **Open Anyway** near the bottom of System Settings > Privacy & Security and enter your password. If the app already went to the Trash, move it back to Applications and run the command above.

> This is a pre-release. There is no App Store release or Apple notarization yet.

## Build

Only the Command Line Tools are needed, no Xcode (`xcode-select --install`).

```sh
cd macos
./build.sh          # builds dist/HighPen.app (universal, ad-hoc signed)
./build.sh test     # builds, then runs the self-check
open dist/HighPen.app
```

The version is set in one place: `VERSION` in `build.sh`.

## DMG package

```sh
./build.sh dmg      # builds dist/HighPen-<version>.dmg
```

Open the DMG and drag HighPen onto the Applications folder to install it.

The app is not yet signed with an Apple developer certificate or notarized, so macOS blocks it the first time when it comes from a DMG downloaded from the internet. See [Download](#download) for how to open it.

Distributing without the warning requires joining the Apple Developer Program, then Developer ID signing and notarization.

## Features

| Feature | Shortcut | Description |
|---|---|---|
| Mouse spot | ⌃⌥S | A translucent circle that follows the pointer |
| Pen | ⌃⌥P | Write on the screen. Uses pen tablet pressure (toggle with ⌃⌥R) |
| Highlighter | ⌃⌥L | Translucent, drawn beneath pen strokes |
| Eraser | ⌃⌥E | Erases whole strokes. Press again while erasing to clear everything |
| Board | ⌃⌥B | White board → black board → off. Kept separately from the screen annotations |
| Undo | ⌃⌥Z | One stroke, or everything removed by one eraser drag |
| Clear | ⌃⌥C | Clears the current page |
| Note | ⌃⌥T | Text box at the clicked spot. Enter confirms, Shift+Enter adds a line, Esc cancels. Removed only by Clear |
| Zoom | ⌃⌥X | Live 1.5x / 2x / 2.5x zoom. Turning the pen on freezes the view so you can write on the zoomed screen |
| Capture | ⌃⌥F | Saves the screen with ink as a PNG in `~/Pictures/HighPen` and copies it to the clipboard |
| Settings | ⌃⌥D | Colors, widths, spot, zoom level, monitor, language (Korean, Japanese, English) |
| Collapse/expand | ⌃⌥H | Collapses the toolbar |
| Cycle monitor | ⌃⌥M | Changes the monitor HighPen works on, with several monitors |
| Pen color | ⌃⌥1 – ⌃⌥8 | Red, orange, yellow, green, blue, purple, black, white (the highlighter color while the highlighter is on) |
| About | | Version, author, contact, license |
| Quit | ⌃⌥Q | |

### Changing shortcuts

In Settings > **Shortcuts**, click an item, then press the new combination. Esc cancels, Delete removes the shortcut, and **Reset all** restores every default. A shortcut must include ⌃, ⌥ or ⌘; F1–F20 can be used alone. You are told when a combination is already used for another item or by another app.

Drag the toolbar by its header to move it; its position and all settings are saved automatically. Clicking the Dock icon expands a collapsed toolbar. Hover over a toolbar button or a settings item to see its name and shortcut.

With several monitors, HighPen remembers the monitor chosen under **Monitor** in Settings (or with ⌃⌥M), even if the monitor order changes. If that monitor is disconnected, HighPen moves to the main monitor, and returns once it is connected again (zoom is turned off if it was on).

Turning on the pen, highlighter or eraser changes the pointer to that tool. Only the active app can change the pointer on macOS, so HighPen becomes the active app while pen mode (or the shortcut editor) is on, and hands focus back to the app you were using (a slideshow, for example) afterwards. Keyboard input (such as advancing slides) therefore does not reach that app during pen mode. HighPen's shortcuts always work.

## Permissions

Zoom and capture need the **Screen Recording** permission. When asked on first use, turn on HighPen in System Settings > Privacy & Security > Screen & System Audio Recording, then **quit and reopen HighPen** (macOS applies the permission only after a relaunch).

The app is signed against its bundle id (`com.stepanowon.HighPen`) so the permission survives rebuilds. If a permission granted to an earlier build does not work, reset it with `tccutil reset ScreenCapture com.stepanowon.HighPen` and turn it on again.

## Differences from the Windows version

- Shortcuts use `⌃⌥` (Control+Option) instead of `Ctrl+Alt`. Pen colors moved to `⌃⌥1–8` so they do not clash with other apps.
- Not available yet: speech bubbles, click display.
- Zoom does not confine the pointer to the monitor (macOS has no such feature).

## Layout

| Path | Contents |
|---|---|
| `src/HighPen/` | App sources (AppKit, ScreenCaptureKit, Carbon hotkeys), one file per responsibility: `main.swift` (entry point), `Controller.swift` (wiring), `ToolState.swift` (tool rules), `InkView.swift` / `Stroke.swift` (ink, speech bubbles), `Toolbar.swift`, `SettingsPanel.swift`, `Hints.swift`, `Popups.swift` (toast, about), `HotkeyEditor.swift`, `Hotkeys.swift` / `Hotkey.swift` (shortcuts), `Zoomer.swift`, `ScreenCapture.swift`, `Spot.swift`, `FocusKeeper.swift`, `Settings.swift`, `Monitors.swift`, `Lang.swift`, `Theme.swift` / `Controls.swift`, `SelfTest.swift` |
| `src/make-icon.swift` | Draws the app icon at every size (the Windows icon's design on the macOS icon grid) |
| `build.sh` | Builds arm64 and x86_64 with `swiftc` → `lipo` → `.app` bundle, icon, ad-hoc signing, DMG packaging |
