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
    let clicks = Clicks()
    let breakTimer = BreakTimer()
    let hints = Hints()
    let focus = FocusKeeper()
    let toast = Toast()
    let about = AboutBox()
    let update = UpdateBox()
    lazy var hotkeys = Hotkeys(makeActions())
    lazy var toolbar = Toolbar(hints: hints)
    lazy var settings = SettingsPanel(hints: hints, hotkeys: hotkeys, delegate: self)
    lazy var editor = HotkeyEditor(hotkeys: hotkeys)
    let penCursor = symbolCursor("pencil"), highlightCursor = symbolCursor("highlighter"), eraserCursor = ringCursor(16), textCursor = NSCursor.iBeam, shapeCursor = NSCursor.crosshair

    var tools = ToolState()
    var settingsOpen = false, collapsed = false, checkingUpdate = false
    var capturing = 0 // captures under way
    private var keyMonitor: Any? // kept: AppKit holds event monitors only as long as the app does

    // Every action that can have a shortcut, in the order the shortcut editor lists them.
    func makeActions() -> [HotkeyAction] {
        let ctrlOpt = controlKey | optionKey
        var a: [HotkeyAction] = [
            HotkeyAction(id: "Spot", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_S, name: "S"), title: { Lang.t("MouseSpot") }, run: { [unowned self] in self.toggleSpot() }),
            HotkeyAction(id: "Clicks", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_K, name: "K"), title: { Lang.t("ClickShow") }, run: { [unowned self] in self.toggleClicks() }),
            HotkeyAction(id: "Pen", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_P, name: "P"), title: { Lang.t("Pen") }, run: { [unowned self] in self.togglePen() }),
            HotkeyAction(id: "Highlighter", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_L, name: "L"), title: { Lang.t("Highlighter") }, run: { [unowned self] in self.toggleHighlighter() }),
            HotkeyAction(id: "Shape", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_O, name: "O"), title: { Lang.t("ShapeTip") }, run: { [unowned self] in self.cycleShape() }),
            HotkeyAction(id: "Eraser", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_E, name: "E"), title: { Lang.t("Eraser") }, run: { [unowned self] in self.eraserHotkey() }),
            HotkeyAction(id: "Bubble", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_T, name: "T"), title: { Lang.t("Bubble") }, run: { [unowned self] in self.toggleBubble() }),
            HotkeyAction(id: "Board", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_B, name: "B"), title: { Lang.t("Board") }, run: { [unowned self] in self.cycleBoard() }),
            HotkeyAction(id: "Undo", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Z, name: "Z"), title: { Lang.t("Undo") }, run: { [unowned self] in self.ink.undo() }),
            HotkeyAction(id: "Clear", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_C, name: "C"), title: { Lang.t("ClearTip") }, run: { [unowned self] in self.ink.clear() }),
            HotkeyAction(id: "Zoom", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_X, name: "X"), title: { Lang.t("Zoom") }, run: { [unowned self] in self.toggleZoom() }),
            HotkeyAction(id: "ZoomLock", def: Hotkey(mods: controlKey | shiftKey, key: kVK_ANSI_X, name: "X"), title: { Lang.t("ZoomLock") }, run: { [unowned self] in self.toggleZoomLock() }),
            HotkeyAction(id: "Capture", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_F, name: "F"), title: { Lang.t("Capture") }, run: { [unowned self] in self.capture() }),
            HotkeyAction(id: "Break", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_W, name: "W"), title: { Lang.t("BreakTip") }, run: { [unowned self] in self.toggleBreak() }),
            HotkeyAction(id: "Settings", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_D, name: "D"), title: { Lang.t("Settings") }, run: { [unowned self] in self.toggleSettings() }),
            HotkeyAction(id: "Collapse", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_H, name: "H"), title: { Lang.t("Collapse") }, run: { [unowned self] in self.toggleCollapse() }),
            HotkeyAction(id: "Monitor", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_M, name: "M"), title: { Lang.t("Monitor") + " (" + Lang.t("Cycle") + ")" }, run: { [unowned self] in self.cycleMonitor() }),
            HotkeyAction(id: "Pressure", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_R, name: "R"), title: { Lang.t("Pressure") }, run: { [unowned self] in self.togglePressure() }),
            HotkeyAction(id: "Quit", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Q, name: "Q"), title: { Lang.t("Quit") }, run: { NSApp.terminate(nil) }),
        ]
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        for (i, key) in zip(Cfg.palette.indices, digits) {
            a.append(HotkeyAction(id: "Color" + String(i), def: Hotkey(mods: ctrlOpt, key: key, name: String(i + 1)),
                                  title: { Lang.t("PenColor") + ": " + Lang.t(Cfg.colorNames[i]) },
                                  run: { [unowned self] in self.setPenColor(i) }))
        }
        return a
    }

    // A button runs the same action as its shortcut (id), unless run is given: the eraser button only toggles
    // the eraser (its shortcut, pressed again, clears the page), and About has no shortcut.
    func toolbarButtons() -> [ToolbarButton] {
        func button(_ id: String, _ symbol: String, _ title: String, tip: String? = nil, more: String = "", tint: NSColor = .white,
                    run: (() -> Void)? = nil) -> ToolbarButton {
            ToolbarButton(id, symbol, Lang.t(title), hotkeys.tip(Lang.t(tip ?? title), id) + more, tint: tint, run ?? hotkeys.action(id)!.run)
        }
        return [
            button("Spot", "smallcircle.filled.circle", "Spot", tip: "MouseSpot"),
            button("Pen", "pencil.tip", "Pen"),
            button("Highlighter", "highlighter", "Highlighter"),
            button("Shape", "square.on.circle", "Shape", tip: "ShapeTip", more: "\n" + Lang.t("ShapeSquare")),
            button("Eraser", "eraser", "Eraser", more: "\n" + Lang.t("EraserTip")) { [unowned self] in self.toggleEraser() },
            button("Board", "rectangle.inset.filled", "Board", tip: "BoardTip"),
            button("Undo", "arrow.uturn.backward", "Undo"),
            button("Clear", "trash", "Clear", tip: "ClearTip"),
            button("Bubble", "text.bubble", "Bubble", more: "\n" + Lang.t("BubbleTip")),
            button("Zoom", "plus.magnifyingglass", "Zoom", more: "\n" + hotkeys.tip(Lang.t("ZoomLock"), "ZoomLock")),
            button("Capture", "camera", "Capture", tip: "CaptureTip"),
            button("Break", "stopwatch", "Break", tip: "BreakTip"),
            button("Settings", "gearshape", "Settings"),
            button("About", "info.circle", "About", tip: "AboutTip") { [unowned self] in self.about.toggle() },
            button("Quit", "xmark.circle.fill", "Quit", tint: alertRed),
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
                : Stroke(color: Cfg.palette[Cfg.penColor], width: Cfg.penSize, highlighter: false, pressure: Cfg.pressure && !self.tools.tool.isShape)
        }
        zoomer.onChange = { [unowned self] in self.applyZoomTransform() }
        zoomer.onStop = { [unowned self] in self.syncToolbar() }
        spot.toShown = { [unowned self] in self.zoomer.shown($0) }
        clicks.toShown = spot.toShown
        clicks.allowed = { [unowned self] in !self.tools.penMode } // while drawing every pen stroke would be a click
        hints.avoid = { [unowned self] w in w === self.toolbar.window && self.settings.window.isVisible ? self.settings.window.frame : nil }
        toolbar.onMove = { [unowned self] in self.placeSettings() }
        hints.along = { [unowned self] w in w === self.toolbar.window ? self.toolbar.edge : .free }
        toolbar.onEdgeChange = { [unowned self] in
            self.hints.hide()
            self.settings.wide = self.toolbar.horizontal
            self.placeSettings()
        }
        editor.onOpen = { [unowned self] in self.updateFocus() }
        editor.onClose = { [unowned self] in
            self.hotkeys.register()
            self.rebuild() // hints show the new shortcuts
            self.updateFocus()
            self.reportFailedHotkeys()
        }

        hotkeys.start()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] e in
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
        clicks.apply()
        if Updater.version(appVersion) != nil { Updater.check { [unowned self] u, _ in if let u = u { self.update.show(u) } } }
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
        if update.isOpen && e.keyCode == kVK_Escape { update.close(); return true }
        return false
    }

    // ---------- layout ----------

    func placeWindows() {
        overlay.setFrame(screen(Cfg.monitor).frame, display: true)
        breakTimer.window.setFrame(screen(Cfg.monitor).frame, display: true)
        clicks.place(screen(Cfg.monitor).frame)
        placeBar()
    }

    func placeBar() {
        toolbar.place()
        placeSettings()
    }

    func placeSettings() { settings.place(beside: toolbar.window.frame, edge: toolbar.edge, visible: settingsOpen && !collapsed) }

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
    func cycleShape() { tools.cycleShape(); applyMode() }
    // First press enters eraser mode; pressing again while erasing wipes the page.
    func eraserHotkey() { if tools.erasing { ink.clear() } else { toggleEraser() } }
    func toggleSettings() { settingsOpen.toggle(); syncToolbar() }
    func toggleCollapse() { collapsed.toggle(); hints.hide(); syncToolbar() }
    func toggleClicks() { Cfg.showClicks.toggle(); clicksChanged(); settings.showSwitches() }
    func togglePressure() { Cfg.pressure.toggle(); settings.showSwitches() }

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
    func clicksChanged() { clicks.apply() }

    // The Update check button: shows the new version, or says HighPen is up to date or could not check.
    func checkForUpdates() {
        guard !checkingUpdate else { return }
        checkingUpdate = true
        Updater.check { [unowned self] u, error in
            self.checkingUpdate = false
            if let u = u { self.update.show(u) }
            else { self.toast.show(error ?? String(format: Lang.t("UpdateLatest"), appVersion), seconds: 4) }
        }
    }

    func toggleZoom() {
        if zoomer.active { zoomer.stop(); syncToolbar(); return }
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        Task { @MainActor in
            do { try await zoomer.start(screen(Cfg.monitor), factor: Cfg.zoomFactors[Cfg.zoomIndex]) }
            catch { askPermission() }
            syncToolbar()
        }
    }

    // Keeps the zoomed view where it is while the pointer moves on (and lets it follow again). Only while zoomed.
    func toggleZoomLock() {
        guard zoomer.active else { return }
        zoomer.locked.toggle()
        syncToolbar()
    }

    func toggleBreak() {
        if breakTimer.running { breakTimer.stop() } else { breakTimer.start(Cfg.breakMinutes) }
        applyZoomPointer()
        syncToolbar()
    }

    func applyZoomTransform() {
        if let o = zoomer.origin, tools.board == .screen {
            ink.zoomScale = zoomer.factor
            ink.zoomOrigin = o
        } else {
            ink.zoomScale = 1
            ink.zoomOrigin = .zero
        }
        ink.needsDisplay = true
    }

    // The zoom shows the real pointer, not its drawn one: in pen mode (the overlay takes input on the display),
    // while the break screen covers the zoomed image, and during a capture (the drawn pointer would be in the picture).
    func applyZoomPointer() { zoomer.direct = tools.penMode || breakTimer.running || capturing > 0 }

    func applySpot() {
        spot.apply()
        toolbar.highlight("Spot", Cfg.spotOn)
    }

    func applyMode() {
        applyTool()
        syncToolbar()
    }

    // The tool and page: ink, cursor, focus, whether the overlay takes the mouse, its background, the zoom.
    func applyTool() {
        if tools.tool != .text || ink.page != tools.board.rawValue { ink.endBubble(commit: true) } // switching tool or page confirms the note being typed
        let t = tools
        ink.page = t.board.rawValue
        ink.tool = t.tool
        ink.cursor = t.tool == .text ? textCursor : t.tool == .eraser ? eraserCursor : t.tool == .highlighter ? highlightCursor : t.tool.isShape ? shapeCursor : penCursor
        updateFocus()
        (t.penMode ? ink.cursor : NSCursor.arrow).set() // the pointer may already be over the overlay
        overlay.ignoresMouseEvents = !t.penMode
        overlay.backgroundColor = t.board.color ?? (t.penMode ? NSColor(white: 0, alpha: 1.0 / 255) : .clear)
        applyZoomPointer()
        applyZoomTransform()
    }

    // What the toolbar shows (which buttons are on, the Board and Zoom labels, collapsed), and where it and the settings panel are.
    func syncToolbar() {
        let t = tools
        toolbar.highlight("Pen", t.penMode && t.tool == .pen)
        toolbar.highlight("Highlighter", t.penMode && t.tool == .highlighter)
        let shape = t.penMode && t.tool.isShape ? t.tool : nil
        toolbar.highlight("Shape", shape != nil)
        toolbar.setTitle("Shape", Lang.t(shape == .rect ? "Rectangle" : shape == .ellipse ? "Ellipse" : "Shape"),
                         symbol: shape == .rect ? "rectangle" : shape == .ellipse ? "circle" : "square.on.circle")
        toolbar.highlight("Eraser", t.erasing)
        toolbar.highlight("Bubble", t.penMode && t.tool == .text)
        toolbar.highlight("Board", t.board != .screen)
        toolbar.highlight("Zoom", zoomer.active)
        toolbar.setTitle("Zoom", Lang.t(zoomer.active && zoomer.locked ? "ZoomLocked" : "Zoom")) // locked, the button reads "Locked"
        toolbar.highlight("Break", breakTimer.running)
        toolbar.highlight("Settings", settingsOpen)
        toolbar.setTitle("Board", Lang.t(t.board.titleKey))
        toolbar.setCollapsed(collapsed)
        placeBar()
    }

    func updateFocus() { focus.update(need: tools.penMode || editor.isOpen) }

    // ---------- capture ----------

    // Captures the selected monitor as shown without the toolbar, settings panel and spot.
    func capture() {
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        toast.close()
        let scr = screen(Cfg.monitor)
        let hide = [toolbar.window, settings.window, spot.window, clicks.window].map { CGWindowID($0.windowNumber) }
        hints.hide() // the hint of the Capture button would be in the picture
        capturing += 1
        applyZoomPointer()
        CATransaction.flush() // the drawn pointer is only gone once the change reaches the screen
        Task { @MainActor in
            defer { capturing -= 1; applyZoomPointer() }
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
