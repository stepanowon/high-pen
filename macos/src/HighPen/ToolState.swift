import Cocoa

// ---------- tool state (which tool is on and which page is shown; no windows, so the rules can be self-checked) ----------

enum Tool { case pen, highlighter, eraser, text }

struct ToolState {
    var penMode = false, tool = Tool.pen
    var board = 0 // 0 = screen, 1 = white board, 2 = black board

    var erasing: Bool { penMode && tool == .eraser }

    mutating func togglePen() { if penMode && tool == .pen { setPen(false) } else { tool = .pen; setPen(true) } }
    mutating func toggleHighlighter() { if penMode && tool == .highlighter { setPen(false) } else { tool = .highlighter; setPen(true) } }
    mutating func toggleEraser() { if erasing { tool = .pen } else { tool = .eraser; penMode = true } }
    mutating func toggleBubble() { if penMode && tool == .text { tool = .pen } else { tool = .text; penMode = true } }

    mutating func setPen(_ on: Bool) {
        penMode = on
        if !on { tool = .pen; board = 0 }
    }

    mutating func cycleBoard() {
        board = (board + 1) % 3
        if board != 0 { penMode = true; if tool == .eraser { tool = .pen } }
    }

    // Keeps the pen visible against the board colour.
    func visiblePenColor(_ c: Int) -> Int {
        if board == 2 && c == Cfg.black { return Cfg.white }
        if board == 1 && c == Cfg.white { return Cfg.black }
        return c
    }
}
