import Cocoa
import Carbon.HIToolbox

// ---------- app ----------

// Wires the windows and services together and turns buttons and shortcuts into changes of the tool state.
@MainActor
final class Controller: NSObject, NSApplicationDelegate, SettingsPanelDelegate {
    let overlay = Panel(level: 1, clickThrough: true)
    let ink = InkView()
    let zoomer = Zoomer()
    let spot = Spot()
    let hints = Hints()
    let focus = FocusKeeper()
    let toast = Toast()
    let about = AboutBox()
    lazy var hotkeys = Hotkeys(makeActions())
    lazy var toolbar = Toolbar(hints: hints)
    lazy var settings = SettingsPanel(hints: hints, hotkeys: hotkeys, delegate: self)
    lazy var editor = HotkeyEditor(hotkeys: hotkeys)
    let penCursor = symbolCursor("pencil"), highlightCursor = symbolCursor("highlighter"), eraserCursor = ringCursor(16), textCursor = NSCursor.iBeam

    var tools = ToolState()
    var settingsOpen = false, collapsed = false

    // Every action that can have a shortcut, in the order the shortcut editor lists them.
    func makeActions() -> [HotkeyAction] {
        let ctrlOpt = controlKey | optionKey
        var a: [HotkeyAction] = [
            HotkeyAction(id: "Spot", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_S, name: "S"), title: { Lang.t("MouseSpot") }, run: { [unowned self] in self.toggleSpot() }),
            HotkeyAction(id: "Pen", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_P, name: "P"), title: { Lang.t("Pen") }, run: { [unowned self] in self.togglePen() }),
            HotkeyAction(id: "Highlighter", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_L, name: "L"), title: { Lang.t("Highlighter") }, run: { [unowned self] in self.toggleHighlighter() }),
            HotkeyAction(id: "Eraser", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_E, name: "E"), title: { Lang.t("Eraser") }, run: { [unowned self] in self.eraserHotkey() }),
            HotkeyAction(id: "Bubble", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_T, name: "T"), title: { Lang.t("Bubble") }, run: { [unowned self] in self.toggleBubble() }),
            HotkeyAction(id: "Board", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_B, name: "B"), title: { Lang.t("Board") }, run: { [unowned self] in self.cycleBoard() }),
            HotkeyAction(id: "Undo", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Z, name: "Z"), title: { Lang.t("Undo") }, run: { [unowned self] in self.ink.undo() }),
            HotkeyAction(id: "Clear", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_C, name: "C"), title: { Lang.t("ClearTip") }, run: { [unowned self] in self.ink.clear() }),
            HotkeyAction(id: "Zoom", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_X, name: "X"), title: { Lang.t("Zoom") }, run: { [unowned self] in self.toggleZoom() }),
            HotkeyAction(id: "Capture", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_F, name: "F"), title: { Lang.t("Capture") }, run: { [unowned self] in self.capture() }),
            HotkeyAction(id: "Settings", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_D, name: "D"), title: { Lang.t("Settings") }, run: { [unowned self] in self.toggleSettings() }),
            HotkeyAction(id: "Collapse", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_H, name: "H"), title: { Lang.t("Collapse") }, run: { [unowned self] in self.toggleCollapse() }),
            HotkeyAction(id: "Monitor", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_M, name: "M"), title: { Lang.t("Monitor") + " (" + Lang.t("Cycle") + ")" }, run: { [unowned self] in self.cycleMonitor() }),
            HotkeyAction(id: "Pressure", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_R, name: "R"), title: { Lang.t("Pressure") }, run: { [unowned self] in self.togglePressure() }),
            HotkeyAction(id: "Quit", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Q, name: "Q"), title: { Lang.t("Quit") }, run: { NSApp.terminate(nil) }),
        ]
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8]
        for i in 0..<Cfg.palette.count {
            a.append(HotkeyAction(id: "Color" + String(i), def: Hotkey(mods: ctrlOpt, key: digits[i], name: String(i + 1)),
                                  title: { Lang.t("PenColor") + ": " + Lang.t(Cfg.colorNames[i]) },
                                  run: { [unowned self] in self.setPenColor(i) }))
        }
        return a
    }

    func toolbarButtons() -> [ToolbarButton] {
        let tip = hotkeys.tip
        return [
            ToolbarButton("Spot", "smallcircle.filled.circle", Lang.t("Spot"), tip(Lang.t("MouseSpot"), "Spot")) { [unowned self] in self.toggleSpot() },
            ToolbarButton("Pen", "pencil.tip", Lang.t("Pen"), tip(Lang.t("Pen"), "Pen")) { [unowned self] in self.togglePen() },
            ToolbarButton("Highlighter", "highlighter", Lang.t("Highlighter"), tip(Lang.t("Highlighter"), "Highlighter")) { [unowned self] in self.toggleHighlighter() },
            ToolbarButton("Eraser", "eraser", Lang.t("Eraser"), tip(Lang.t("Eraser"), "Eraser") + "\n" + Lang.t("EraserTip")) { [unowned self] in self.toggleEraser() },
            ToolbarButton("Board", "rectangle.inset.filled", Lang.t("Board"), tip(Lang.t("BoardTip"), "Board")) { [unowned self] in self.cycleBoard() },
            ToolbarButton("Undo", "arrow.uturn.backward", Lang.t("Undo"), tip(Lang.t("Undo"), "Undo")) { [unowned self] in self.ink.undo() },
            ToolbarButton("Clear", "trash", Lang.t("Clear"), tip(Lang.t("ClearTip"), "Clear")) { [unowned self] in self.ink.clear() },
            ToolbarButton("Bubble", "text.bubble", Lang.t("Bubble"), tip(Lang.t("Bubble"), "Bubble") + "\n" + Lang.t("BubbleTip")) { [unowned self] in self.toggleBubble() },
            ToolbarButton("Zoom", "plus.magnifyingglass", Lang.t("Zoom"), tip(Lang.t("Zoom"), "Zoom")) { [unowned self] in self.toggleZoom() },
            ToolbarButton("Capture", "camera", Lang.t("Capture"), tip(Lang.t("CaptureTip"), "Capture")) { [unowned self] in self.capture() },
            ToolbarButton("Settings", "gearshape", Lang.t("Settings"), tip(Lang.t("Settings"), "Settings")) { [unowned self] in self.toggleSettings() },
            ToolbarButton("About", "info.circle", Lang.t("About"), Lang.t("AboutTip")) { [unowned self] in self.about.toggle() },
            ToolbarButton("Quit", "xmark.circle.fill", Lang.t("Quit"), tip(Lang.t("Quit"), "Quit"), tint: rgb(0xFF453A)) { NSApp.terminate(nil) },
        ]
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        Lang.cur = Lang.index(Cfg.language)
        setupMenu()

        overlay.contentView = ink
        overlay.keyable = true // typing into a speech bubble
        ink.bubbleStyle = { (Cfg.palette[Cfg.penColor], max(16, CGFloat(Cfg.penSize) * 4)) }
        ink.onBubbleEnd = { [unowned self] in if self.tools.tool == .text { self.tools.tool = .pen; self.applyMode() } }
        ink.newStroke = { [unowned self] in
            self.tools.tool == .highlighter
                ? Stroke(color: Cfg.palette[Cfg.highlightColor], width: Cfg.highlightSize, highlighter: true, pressure: false)
                : Stroke(color: Cfg.palette[Cfg.penColor], width: Cfg.penSize, highlighter: false, pressure: Cfg.pressure)
        }
        zoomer.onChange = { [unowned self] in self.applyZoomTransform() }
        hints.avoid = { [unowned self] w in w === self.toolbar.window && self.settings.window.isVisible ? self.settings.window.frame : nil }
        toolbar.onMove = { [unowned self] in self.placeSettings() }
        editor.onOpen = { [unowned self] in self.updateFocus() }
        editor.onClose = { [unowned self] in
            self.hotkeys.register()
            self.rebuild() // hints show the new shortcuts
            self.updateFocus()
            self.reportFailedHotkeys()
        }

        hotkeys.start()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] e in
            MainActor.assumeIsolated { self.handleKey(e) } ? nil : e
        }

        rebuild()
        placeWindows()
        overlay.orderFrontRegardless()
        toolbar.window.orderFrontRegardless()

        focus.start()
        // keep up with monitors being plugged in or removed (and resolution changes) while running
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [unowned self] _ in
            MainActor.assumeIsolated {
                self.zoomer.stop() // the zoomed monitor may be gone
                self.rebuild()
                self.placeWindows()
            }
        }
        reportFailedHotkeys()
    }

    // Launching again or clicking the Dock icon brings the toolbar back.
    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if collapsed { toggleCollapse() }
        toolbar.window.orderFrontRegardless()
        return false
    }

    func applicationWillTerminate(_ n: Notification) { zoomer.stop() }

    func setupMenu() {
        let menu = NSMenu()
        let item = NSMenuItem()
        menu.addItem(item)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: Lang.t("Quit") + " HighPen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = appMenu
        NSApp.mainMenu = menu
    }

    func reportFailedHotkeys() {
        if let note = hotkeys.failureNote { toast.show(note, seconds: 8) }
    }

    // Every key goes to the shortcut editor while it is open (whichever HighPen window has focus,
    // which can change when the app activates); Esc / Return close the about box.
    func handleKey(_ e: NSEvent) -> Bool {
        if editor.isOpen { editor.key(e); return true }
        if about.isOpen && (e.keyCode == kVK_Escape || e.keyCode == kVK_Return) { about.toggle(); return true }
        return false
    }

    // ---------- layout ----------

    func placeWindows() {
        overlay.setFrame(screen(Cfg.monitor).frame, display: true)
        placeBar()
    }

    func placeBar() {
        toolbar.place()
        placeSettings()
    }

    func placeSettings() { settings.place(beside: toolbar.window.frame, visible: settingsOpen && !collapsed) }

    func rebuild() {
        hints.hide() // its control is about to go away
        toolbar.build(toolbarButtons(), collapseTip: hotkeys.tip(Lang.t("Collapse"), "Collapse")) { [unowned self] in self.toggleCollapse() }
        settings.rebuild()
        applySpot()
        applyMode()
    }

    // ---------- behaviour ----------

    func toggleSpot() { Cfg.spotOn.toggle(); applySpot() }
    func togglePen() { tools.togglePen(); applyMode() }
    func toggleHighlighter() { tools.toggleHighlighter(); applyMode() }
    func toggleEraser() { tools.toggleEraser(); applyMode() }
    func toggleBubble() { tools.toggleBubble(); applyMode() }
    // First press enters eraser mode; pressing again while erasing wipes the page.
    func eraserHotkey() { if tools.erasing { ink.clear() } else { toggleEraser() } }
    func toggleSettings() { settingsOpen.toggle(); applyMode() }
    func toggleCollapse() { collapsed.toggle(); hints.hide(); applyMode() }
    func togglePressure() { Cfg.pressure.toggle(); settings.rebuild(); placeSettings() }

    func cycleBoard() {
        tools.cycleBoard()
        Cfg.penColor = tools.visiblePenColor(Cfg.penColor)
        settings.showPenColor(Cfg.penColor)
        applyMode()
    }

    // Colour shortcuts change the tool in use: the highlighter while it is on, otherwise the pen.
    func setPenColor(_ i: Int) {
        if tools.tool == .highlighter { Cfg.highlightColor = i; settings.showHighlightColor(i) }
        else { Cfg.penColor = i; settings.showPenColor(i) }
    }

    func cycleMonitor() { setMonitor((Cfg.monitor + 1) % NSScreen.screens.count) }

    func setMonitor(_ i: Int) {
        guard i != Cfg.monitor || !Cfg.monitorChosen else { return } // picking the fallback monitor makes it the choice
        zoomer.stop() // zoom belongs to the previous monitor
        Cfg.monitor = i
        rebuild()
        placeWindows()
    }

    func setLanguage(_ i: Int) {
        guard i != Lang.cur else { return }
        Lang.cur = i
        Cfg.language = Lang.codes[i]
        setupMenu()
        rebuild()
    }

    func spotChanged() { applySpot() }
    func zoomChanged() { zoomer.setFactor(Cfg.zoomFactors[Cfg.zoomIndex]) }
    func showHotkeyEditor() { editor.show() }

    func toggleZoom() {
        if zoomer.active { zoomer.stop(); applyMode(); return }
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        Task { @MainActor in
            do { try await zoomer.start(screen(Cfg.monitor), factor: Cfg.zoomFactors[Cfg.zoomIndex]) }
            catch { askPermission() }
            applyMode()
        }
    }

    func applyZoomTransform() {
        if let o = zoomer.origin, tools.board == 0 {
            ink.zoomScale = zoomer.factor
            ink.zoomOrigin = o
        } else {
            ink.zoomScale = 1
            ink.zoomOrigin = .zero
        }
        ink.needsDisplay = true
    }

    func applySpot() {
        spot.apply()
        toolbar.highlight("Spot", Cfg.spotOn)
    }

    func applyMode() {
        if tools.tool != .text || ink.page != tools.board { ink.endBubble(commit: true) } // switching tool or page confirms the note being typed
        let t = tools
        ink.page = t.board
        ink.tool = t.tool
        ink.cursor = t.tool == .text ? textCursor : t.tool == .eraser ? eraserCursor : t.tool == .highlighter ? highlightCursor : penCursor
        updateFocus()
        (t.penMode ? ink.cursor : NSCursor.arrow).set() // the pointer may already be over the overlay
        overlay.ignoresMouseEvents = !t.penMode
        overlay.backgroundColor = t.board == 1 ? .white : t.board == 2 ? .black : t.penMode ? NSColor(white: 0, alpha: 1.0 / 255) : .clear
        zoomer.frozen = t.penMode
        applyZoomTransform()

        toolbar.highlight("Pen", t.penMode && t.tool == .pen)
        toolbar.highlight("Highlighter", t.penMode && t.tool == .highlighter)
        toolbar.highlight("Eraser", t.erasing)
        toolbar.highlight("Bubble", t.penMode && t.tool == .text)
        toolbar.highlight("Board", t.board != 0)
        toolbar.highlight("Zoom", zoomer.active)
        toolbar.highlight("Settings", settingsOpen)
        toolbar.setTitle("Board", Lang.t(["Board", "WhiteBoard", "BlackBoard"][t.board]))
        toolbar.setCollapsed(collapsed)
        placeBar()
    }

    func updateFocus() { focus.update(need: tools.penMode || editor.isOpen) }

    // ---------- capture ----------

    // Captures the selected monitor as shown without the toolbar, settings panel and spot.
    func capture() {
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        toast.hide()
        let scr = screen(Cfg.monitor)
        let hide = [toolbar.window, settings.window, spot.window].map { CGWindowID($0.windowNumber) }
        Task { @MainActor in
            do {
                let url = try await ScreenCapture.save(scr, hiding: hide)
                toast.show(String(format: Lang.t("Saved"), url.path), seconds: 5) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            } catch {
                toast.show(Lang.t("CaptureFailed") + "\n" + error.localizedDescription, seconds: 5)
            }
        }
    }

    func askPermission() {
        CGRequestScreenCaptureAccess()
        toast.show(Lang.t("NeedPermission"), seconds: 10) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }
}
