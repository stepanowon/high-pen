import Cocoa

// ---------- tool state (which tool is on and which page is shown; no windows, so the rules can be self-checked) ----------

enum Tool {
    case pen, highlighter, eraser, text, rect, ellipse
    var isShape: Bool { self == .rect || self == .ellipse }
}

// The page shown: the screen itself, or a board covering it. The raw value is the ink page.
enum Board: Int, CaseIterable {
    case screen, white, black

    var titleKey: String { ["Board", "WhiteBoard", "BlackBoard"][rawValue] }
    var color: NSColor? { self == .white ? .white : self == .black ? .black : nil }
    var next: Board { Board(rawValue: (rawValue + 1) % Board.allCases.count)! }
}

struct ToolState {
    var penMode = false, tool = Tool.pen
    var board = Board.screen

    var erasing: Bool { penMode && tool == .eraser }

    mutating func togglePen() { if penMode && tool == .pen { setPen(false) } else { tool = .pen; setPen(true) } }
    mutating func toggleHighlighter() { if penMode && tool == .highlighter { setPen(false) } else { tool = .highlighter; setPen(true) } }
    mutating func toggleEraser() { if erasing { tool = .pen } else { tool = .eraser; penMode = true } }
    // rectangle -> ellipse -> back to the pen
    mutating func cycleShape() {
        if penMode && tool == .rect { tool = .ellipse }
        else if penMode && tool == .ellipse { tool = .pen }
        else { tool = .rect; penMode = true }
    }
    mutating func toggleBubble() { if penMode && tool == .text { tool = .pen } else { tool = .text; penMode = true } }

    mutating func setPen(_ on: Bool) {
        penMode = on
        if !on { tool = .pen; board = .screen }
    }

    mutating func cycleBoard() {
        board = board.next
        if board != .screen { penMode = true; if tool == .eraser { tool = .pen } }
    }

    // Keeps the pen visible against the board colour.
    func visiblePenColor(_ c: Int) -> Int {
        if board == .black && c == Cfg.black { return Cfg.white }
        if board == .white && c == Cfg.white { return Cfg.black }
        return c
    }
}
