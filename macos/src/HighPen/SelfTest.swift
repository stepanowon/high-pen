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
    print("selftest ok")
}
