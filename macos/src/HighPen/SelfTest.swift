import Cocoa
import Carbon.HIToolbox

// ---------- self-check: swift-run with --selftest ----------

@MainActor
func selfTest() {
    let v = InkView()
    let s = Stroke(color: .red, width: 4, highlighter: false, pressure: false)
    s.add(CGPoint(x: 0, y: 0), 0.5)
    s.add(CGPoint(x: 100, y: 0), 0.5)
    precondition(s.hits(CGPoint(x: 50, y: 1.5), 0) && !s.hits(CGPoint(x: 50, y: 3), 0), "stroke hit test")
    v.pages[0] = [s]
    v.history[0] = [Edit(added: [s])]
    v.erase(at: CGPoint(x: 50, y: 0))
    v.endErase()
    precondition(v.pages[0].isEmpty && v.history[0].count == 2, "erase is one undo step")
    v.undo()
    precondition(v.pages[0].count == 1, "undo restores the erased stroke")
    v.undo()
    precondition(v.pages[0].isEmpty, "undo removes the drawn stroke")
    v.bubbles[0] = [Bubble(text: "a", at: .zero, color: .red, size: 16)]
    v.clear()
    precondition(v.bubbles[0].isEmpty, "clear removes speech bubbles")
    v.pages[0] = [s]
    v.history[0] = []
    v.bubbles[0] = [Bubble(text: "a", at: .zero, color: .red, size: 16)]
    v.clear()
    v.bubbles[0].append(Bubble(text: "b", at: .zero, color: .red, size: 16))
    v.undo()
    precondition(v.pages[0].count == 1 && v.bubbles[0].map(\.text) == ["a", "b"], "undo brings back a clear all, bubbles beneath newer ones")
    v.zoomScale = 2
    v.zoomOrigin = CGPoint(x: 100, y: 50)
    precondition(v.content(CGPoint(x: 40, y: 20)) == CGPoint(x: 120, y: 60), "zoomed input maps back to content")
    let h = Hotkey(mods: controlKey | optionKey, key: kVK_ANSI_P, name: "P")
    precondition(Hotkey(saved: h.saved).map { $0.same(h) && $0.text == "⌃⌥P" } == true, "shortcut round trip")
    precondition(Hotkey(saved: "4096:41::")?.name == ":" && Hotkey(saved: "x") == nil, "shortcut parsing")
    precondition(Hotkey.asciiName(kVK_ANSI_P) == "P", "key names come from the ASCII layout")
    var t = ToolState()
    t.togglePen()
    precondition(t.penMode && t.tool == .pen, "pen on")
    t.toggleEraser()
    precondition(t.erasing, "eraser on")
    t.togglePen()
    precondition(t.penMode && t.tool == .pen, "pen from the eraser")
    t.cycleBoard()
    precondition(t.board == 1 && t.visiblePenColor(Cfg.white) == Cfg.black && t.visiblePenColor(0) == 0, "white board keeps the pen visible")
    t.cycleBoard()
    precondition(t.board == 2 && t.visiblePenColor(Cfg.black) == Cfg.white, "black board keeps the pen visible")
    t.togglePen()
    precondition(!t.penMode && t.board == 0, "pen off leaves the board")
    precondition(BreakTimes.clamp(7) == 5 && BreakTimes.clamp(8) == 10 && BreakTimes.clamp(0) == 5 && BreakTimes.clamp(999) == 120, "break length steps and range")
    precondition(BreakTimes.clock(599) == "09:59" && BreakTimes.clock(3600) == "1:00:00" && BreakTimes.clock(0) == "00:00", "break clock")
    var e = 0
    precondition(Zoomer.offset(500, 1001, 0.5, &e) == 250 && e == 0, "zoom follows the pointer before an edge")
    precondition(Zoomer.offset(0, 1001, 0.5, &e) == 0 && e == -1 && Zoomer.offset(400, 1001, 0.5, &e) == 0, "zoom holds at the left edge until the middle")
    precondition(Zoomer.offset(750, 1001, 0.5, &e) == 250 && Zoomer.offset(1000, 1001, 0.5, &e) == 500 && e == 1, "zoom reaches the right edge with the pointer")
    precondition(Zoomer.offset(600, 1001, 0.5, &e) == 500 && Zoomer.offset(250, 1001, 0.5, &e) == 250, "zoom holds at the right edge until the middle")
    let rel = #"[{"tag_name":"v9.0.0","html_url":"w"},{"tag_name":"macos-v1.5.0","draft":true,"html_url":"d"},{"tag_name":"macos-v1.4.2","html_url":"https://x/b"},{"tag_name":"macos-v1.4.1","html_url":"a"},{"tag_name":"macos-v1.3.1","html_url":"o"}]"#.data(using: .utf8)!
    precondition(try! Updater.pick(rel, current: "1.4.0")?.version == "1.4.2", "update picks the newest published macOS release")
    precondition(try! Updater.pick(rel, current: "1.4.2") == nil && Updater.version("1.4") == [1, 4, 0] && Updater.version("dev") == nil, "no update when up to date")
    let lang = Lang.cur
    Lang.cur = 0
    precondition(BreakTimes.label(15) == "15분" && BreakTimes.label(60) == "1시간" && BreakTimes.label(90) == "1시간 30분", "break labels")
    Lang.cur = lang
    print("selftest ok")
}
