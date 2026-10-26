# HighPen for Windows

- **한국어:** [한국어로 된 문서는 여기를 보세요.](README.md)
- **English:** You are reading this document.
- **日本語:** [日本語版のドキュメントはこちらです。](README.ja.md)

[← Back to the HighPen overview](../README.en.md)

HighPen is a Windows pen app for online lectures. You can write directly on the screen, highlight the mouse pointer with a spotlight, zoom in on the screen, and bring up a whiteboard or a break timer. It works with pen tablets such as Wacom (Windows Ink) as well as with a mouse.

![HighPen toolbar and mouse spot](../screen/전체화면1.png)

## Installation

### Install from the Microsoft Store (recommended)

[<img src="https://get.microsoft.com/images/en-us%20dark.svg" width="200" alt="Get it from Microsoft"/>](https://apps.microsoft.com/detail/9PDG1QN5QSL3?mode=direct)

It installs without a SmartScreen warning and updates automatically when a new version is released. To uninstall, use **Installed apps** in Windows Settings.

### Install with winget

Run this in a terminal (PowerShell or Command Prompt). It installs the Microsoft Store package, the same as installing from the Store.

```
winget install 9PDG1QN5QSL3 --source msstore
```

- The first install asks you to accept the Microsoft Store terms. Press `Y`, or add `--accept-package-agreements --accept-source-agreements` to skip the prompt.
- Find it by name: `winget search HighPen --source msstore`
- Update: the Store updates it automatically, or run `winget upgrade 9PDG1QN5QSL3`
- Uninstall: `winget uninstall 9PDG1QN5QSL3`

### Run without installing

Download [HighPen.exe](https://github.com/stepanowon/high-pen/raw/main/windows/dist/HighPen.exe) and run it directly. No installation needed.

### Install with the installer

1. Download [HighPen-Setup.exe](https://github.com/stepanowon/high-pen/raw/main/windows/dist/HighPen-Setup.exe) and run it.
2. Confirm the installation and choose whether to create a desktop shortcut.
3. When the installation finishes, you can start the app right away.

- Install location: `%LOCALAPPDATA%\Programs\HighPen` (no administrator rights needed)
- A Start menu shortcut is created.
- Running the same file again overwrites the installed copy to update it.
- Uninstall: remove HighPen from **Installed apps** in Windows Settings, or run `Uninstall.exe` in the install folder. Saved settings (`%APPDATA%\HighPen`) are kept.
- Silent install/uninstall: `HighPen-Setup.exe /S`, `Uninstall.exe /S`
- The installer messages follow the Windows display language (Korean, Japanese, otherwise English).

### Pin to the taskbar

While the app is running, the HighPen icon appears on the taskbar. Right-click it and choose **Pin to taskbar** so you can start it from the icon next time, even when the app is closed.

### Requirements

Windows 10/11 (.NET Framework 4.8 is built in, nothing else to install)

## Usage

When you start the app, the toolbar appears in the top-left corner of the active monitor. Drag the top row (HighPen) to move it; the position is remembered. Use the `<` button to collapse and expand it.

### Changing the language

The default language is **English**. On first launch, buttons and tooltips are shown in English. You can switch while the app is running:

1. Click **Settings** on the toolbar or press `Ctrl+Alt+D` to open the settings panel.
2. Under **Language** near the bottom of the panel, click **日本語** or **한국어**.
3. The change applies immediately without restarting, and the current state (pen, zoom, etc.) is kept.

The chosen language is saved automatically and used on the next launch.

Shortcuts are global, so they work while you are using other programs. A combination already used by another program cannot be registered; in that case HighPen lists the shortcuts it could not register at the bottom of the screen right after starting, and in the settings panel. Hovering over a button shows its name and shortcut as a tooltip. The table lists the default shortcuts; you can change them under **Shortcuts** in the settings panel.

| Button | Shortcut | Function |
|---|---|---|
| Spot | Ctrl+Alt+S | Turns the round spot that follows the mouse pointer on/off. Clicks pass through to the screen below. |
| Pen | Ctrl+Alt+P | Writes on the screen. When the pen is turned off, the ink stays on screen and the mouse passes through to the screen below. Switches back to the pen from eraser or note mode. |
| Highlighter | Ctrl+Alt+L | A wide translucent pen for marking text or pictures. What is underneath stays visible, and it is drawn beneath pen ink. Press again to turn it off. |
| Eraser | Ctrl+Alt+E | Erases whole strokes. Pressing it again while erasing deletes all pen ink and notes on the current page. |
| Board | Ctrl+Alt+B | Cycles white board → black board → off. Ink on the screen and on the two boards is kept separately. |
| Undo | Ctrl+Alt+Z | Cancels the last pen stroke or eraser action. |
| Clear | Ctrl+Alt+C | Clears all ink and notes on the current page. |
| Note | Ctrl+Alt+T | Places a text note where you click. Enter confirms, Shift+Enter adds a line break, Esc cancels. |
| Zoom | Ctrl+Alt+X | Zooms the monitor under the mouse pointer (1.5x, 2x or 2.5x, chosen in Settings). |
| Lock zoom | Ctrl+Shift+X | While zoomed, locks the zoomed view in place or unlocks it. While locked, moving the mouse does not move the view, and the zoom button reads "Locked". |
| Capture | Ctrl+Alt+F | Saves the active monitor, with ink, board and notes, as a PNG and copies it to the clipboard. The toolbar and spot are left out. |
| Break | Ctrl+Alt+W | Starts and stops the break timer. The time left is shown in large digits over the whole active monitor. |
| Settings | Ctrl+Alt+D | Opens and closes the settings panel. |
| About | | Shows the author (name, email, GitHub repository) and license. Clicking a link opens your mail app or browser. |
| `<` | Ctrl+Alt+H | Collapses and expands the toolbar. |
| Red X | Ctrl+Alt+Q | Quit |

### Settings panel

| Item | Shortcut | Description |
|---|---|---|
| Monitor | Ctrl+Alt+M (cycle) | Selects the monitor the app works on. Ink, spot, board and toolbar appear only on the selected monitor. |
| Pen color | Ctrl+Shift+first letter of the color | Red R, Orange O, Yellow Y, Green G, Blue B, Purple P, Black K (B is taken by Blue), White W |
| Pen width | | 1–30 |
| Pressure | Ctrl+Alt+R | The harder you press the pen, the thicker the line. A mouse always draws at the set width. |
| Highlighter color / width | | 8 colors and widths 5–60. While the highlighter is in use, the pen color shortcuts (Ctrl+Shift+…) change the highlighter color. |
| Spot color / size | | 8 colors and sizes 20–200. |
| Break length | | Length of the break timer. Pick 10 min, 15 min, 1 h or 1 h 30 min with the buttons, or 5–120 minutes in 5-minute steps with the slider. Default 10 minutes. |
| Show clicks | Ctrl+Alt+K | Briefly shows an expanding ring where you click. Off by default. |
| Language | | Choose 한국어, 日本語 or English; the change applies immediately. The default is English (see [Changing the language](#changing-the-language)). |
| Shortcuts | | Change any shortcut to the combination you want, or remove it (see [Changing shortcuts](#changing-shortcuts)). |
| Version | | The current version (`HighPen v1.7.2`) is shown at the bottom of the panel. |

Settings are saved automatically to `%APPDATA%\HighPen\settings.txt`.

### Changing shortcuts

Press **Shortcuts** near the bottom of the settings panel to open the list of every feature and its shortcut.

1. Click the shortcut box of the feature you want to change. It shows "Press keys…".
2. Press the new combination. Hold Ctrl or Alt as well; F1–F24 can also be used alone.
3. It is saved right away, and the new shortcuts take effect when you close the window.

- **Esc** cancels; **Delete** (or Backspace) removes the shortcut from that feature.
- If another HighPen feature already uses the combination, the window tells you which one and does not accept it.
- A combination another program uses as a global shortcut goes to that program first, so nothing happens when you press it. Pick another one.
- **Reset all** restores every default shortcut.
- HighPen's shortcuts are paused while the window is open.

### Writing while zoomed

If you turn on the pen while zoomed, the zoomed view freezes in place so you can write exactly where you see things. Turning the pen off makes the zoomed view follow the pointer again. Ink is stored in original screen coordinates, so when you turn zoom off it stays on the same content at normal size.

## Features

### Mouse spot

A semi-transparent round spot follows the mouse pointer so viewers can easily find it.

- The spot does not catch clicks, so you can use the screen below as usual.
- Change its color (8 colors) and size (20–200) in the settings panel. It is a plain colored circle without a border.
- It is shown only on the monitor selected as the active monitor.

### Pen (writing)

A transparent ink layer covers the screen so you can draw directly on it. Both Wacom pens and the mouse work.

![Writing on the screen](../screen/펜1.png)

- **Pen on:** the screen enters writing mode and clicks to the screen below are blocked.
- **Pen off:** your ink stays on screen and the mouse controls the screen below again. You can advance slides with the ink still showing.
- **Color and width:** 8 colors, width 1–30. Colors can also be changed with shortcuts.
- **Pressure:** when on, pressing harder makes lines thicker; the set width corresponds to medium pressure. A mouse draws at a constant width. If pressure does not work, check that Windows Ink is enabled in the Wacom driver.
- **Smoothing:** lines are smoothed into curves.

### Highlighter

Use it to emphasize sentences or pictures in your material. Press the highlighter button (Ctrl+Alt+L) and draw to get a wide translucent stroke.

- Overlapping strokes do not get darker, and what is underneath stays visible. Pen ink drawn on the same spot stays on top of the highlighter.
- Change the color (yellow by default) and width (20 by default) with **Highlighter color** and **Highlighter width** in the settings panel. While the highlighter is in use, the pen color shortcuts (Ctrl+Shift+R and so on) change the highlighter color.
- Eraser, undo and clear work on it just as on pen ink.
- Press the pen button to go back to the normal pen.

### Eraser

Passing over a stroke erases the whole stroke (stroke erasing). The eraser end of a Wacom pen also works.

- Pressing Ctrl+Alt+E again while in eraser mode deletes all pen ink and notes on the current page at once. Other pages are not affected.
- To write again, press the pen button (Ctrl+Alt+P).

### Board

Covers the whole screen with a white or black board to write on. Each press of the board button cycles white board → black board → off.

- Ink on the screen, the white board and the black board is kept separately. Turning a board off and on keeps its content, and board ink does not mix with the on-screen ink.
- A black pen on the black board or a white pen on the white board would be invisible, so the pen switches to the opposite color automatically.
- Zoom does not apply to ink on a board.

| White board | Black board |
|---|---|
| ![White board](../screen/화이트보드.png) | ![Black board](../screen/블랙보드.png) |

### Undo / Clear

- **Undo:** cancels the last action on the current page: one pen stroke, or all strokes removed by one eraser drag. Clear all cannot be undone. Notes cannot be undone.
- **Clear:** removes all ink and notes on the current page. Other pages (screen, white board, black board) are not affected.

### Notes

Attaches a text note to the screen. Use it to leave terms or explanations in clear type instead of handwriting.

1. Press the note button (Ctrl+Alt+T). The pointer changes to a text cursor.
2. Click where you want the note and type its content.
3. Press **Enter** to confirm. **Shift+Enter** adds a line break and **Esc** cancels.

- The note is shown as a rounded white box with a border in the current pen color, and the font size scales with the pen width.
- After one note the app returns to normal pen mode. Press the button again for each additional note.
- Notes cannot be moved or edited after they are created; they can only be removed with Clear.
- Notes belong to the current page (screen, white board, black board) and are kept per page.

![Ink and notes](../screen/펜2.png)

### Zoom

Zooms the monitor under the mouse pointer in real time. Pick 1.5x, 2x or 2.5x in the settings panel; changing it while zoomed applies immediately.

![Zoom](../screen/화면%20확대.png)

- The view moves so that the content under the pointer stays under the pointer after zooming. Just click where you see things.
- The toolbar is not zoomed and keeps its normal size.
- The monitor the pointer was on when zoom was turned on is zoomed, and the pointer cannot leave that monitor while zoomed. To zoom another monitor, turn zoom off, move the pointer, and turn it on again.
- Changing the active monitor while zoomed turns zoom off.
- **Lock the zoomed view (Ctrl+Shift+X):** press it while zoomed to keep the zoomed view where it is, so it no longer moves around as you move the mouse. The zoom button then reads "Locked". Press it again to let the view follow the pointer again. Turning zoom off also unlocks it.
- While locked, what you see is not where a click lands. Use the locked view to explain or write with the pen, and unlock it to click.
- **Writing while zoomed:** turning on the pen freezes the zoomed view so you can write where you see things. Turning the pen off makes the zoomed view follow the pointer again. Ink is stored in original screen coordinates, so it stays on the same content at normal size when zoom is turned off. To move to another area while zoomed, turn the pen off, move the pointer, and turn the pen on again.

### Capture

Use it to keep a board or on-screen ink as lecture material. Press the capture button (Ctrl+Alt+F) to take the active monitor exactly as shown: screen, ink, board, notes and zoomed view.

- **Where it goes:** `Pictures\HighPen\HighPen_date_time.png`. The same image is copied to the clipboard so you can paste it right away.
- The toolbar and the mouse spot are not captured.
- The saved path appears briefly at the bottom of the screen; click it to open the folder in File Explorer.

### Break timer

Shows how much of a break is left during a lecture. Press the break button (Ctrl+Alt+W) and the whole active monitor dims with the time left in large digits, easy to read for viewers on a shared screen.

- **Length:** pick it under **Break length** in the settings panel with the 10 min, 15 min, 1 h and 1 h 30 min buttons or the slider (5–120 minutes in 5-minute steps). It is saved for the next launch. A change made while the timer runs applies to the next break.
- The time the lecture resumes (e.g. "Back at 13:26") is shown under the countdown, and the last minute turns orange.
- When time is up, a red 00:00 and "The break is over" stay on screen until you press the break button or Ctrl+Alt+W again.
- The timer screen lets clicks through, so you can keep using the PC during the break, and the toolbar stays visible above it.

### Show clicks

In recordings and screen shares, a ring expands and fades where you click so viewers can see what you pressed. Turn it on and off with **Show clicks** in the settings panel or Ctrl+Alt+K.

- Left clicks show a solid ring and right clicks a dashed ring, in the spot color.
- Shown only on the active monitor, and not while you are writing with the pen.

### Multiple monitors

Choose the monitor the app works on with **Monitor** in the settings panel (or Ctrl+Alt+M). Ink, spot, board and toolbar appear only on that monitor, and the other monitors can be used as usual. Existing ink and notes are kept when you switch monitors. The numbers match those in Windows display settings. When a monitor is connected or disconnected while the app runs, the monitor list and window positions are updated automatically (zoom is turned off if it was on). If the active monitor is disconnected, HighPen moves to the primary monitor within a second and returns when that monitor is reconnected. The chosen monitor is remembered even if the monitor order changes.

### Toolbar

- Drag the top row (HighPen) to move the toolbar; the position is saved and used on the next launch. If the saved position is off screen, it returns to the top-left corner.
- The toolbar stays inside the selected monitor. Whether you drag it or it grows (expanding, opening the settings panel), it is kept within that monitor's work area (excluding the taskbar).
- Use the `<` button on the left of the top row to collapse and expand it. When collapsed, the HighPen title disappears too and only the `>` button remains, so you can click what was behind the toolbar. Press `>` to expand it again in the same place. The toolbar cannot be dragged while collapsed.

- The settings panel opens to the right of the toolbar, or to its left when the toolbar is at the right edge of the screen.
- Hovering over a button shows its name and shortcut as a tooltip.
- Clicking it does not take focus away from the screen you are presenting.
- While running, its icon appears on the taskbar and can be pinned.

### Saved settings

Pen color, width, pressure, highlighter color and width, changed shortcuts, spot color and size, whether the spot is on, show clicks, the zoom level, the break length, the active monitor, the toolbar position and the language are saved automatically to `%APPDATA%\HighPen\settings.txt` and reused on the next launch.

## Notes / limitations

- The executables are not code-signed, so Windows SmartScreen may show a warning when you download them from the web. Install from the Microsoft Store or with winget, or click **More info → Run anyway** in the warning.
- On setups where monitors use different display scaling, zoom or the toolbar position may be off.
- For a monitor connected through an adapter (e.g. USB-C↔HDMI), Windows may not treat unplugging the monitor-side cable as a disconnect, so HighPen does not move either. Unplug the adapter from the PC, or use **Disconnect this display** in display settings.
- To write while zoomed, the pen must be on so the zoomed view does not follow the pointer.

## Privacy

This program will not transfer any information to other networked systems unless specifically requested by the user or the person installing or operating it. A browser or mail app opens only when you click a link in the About window. See the [privacy policy](../PRIVACY.md#english) for details.

## License

Released under the [MIT License](../LICENSE). You may use, modify and distribute it freely, including for commercial purposes, as long as the copyright and license notice are included.
