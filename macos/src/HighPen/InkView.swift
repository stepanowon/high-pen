import Cocoa

// ---------- ink view ----------

// A text note, top-left at `at` (content coordinates), white with a border in the pen colour.
struct Bubble {
    let text: String, at: CGPoint, color: NSColor, size: CGFloat

    func draw() {
        let str = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.black])
        let r = str.boundingRect(with: NSSize(width: 600, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading])
        let box = NSRect(x: at.x, y: at.y - ceil(r.height) - 12, width: ceil(r.width) + 20, height: ceil(r.height) + 12)
        let p = NSBezierPath(roundedRect: box.insetBy(dx: 1, dy: 1), xRadius: 12, yRadius: 12)
        NSColor(white: 1, alpha: 0xEE / 255.0).setFill(); p.fill()
        p.lineWidth = 2; color.setStroke(); p.stroke()
        str.draw(in: box.insetBy(dx: 10, dy: 6))
    }
}

// One undo step: a pen stroke, every stroke removed by one eraser drag, or a clear all.
struct Edit {
    var added: [Stroke] = []
    var removed: [Stroke] = []
    var bubbles: [Bubble] = [] // the speech bubbles a clear all removed
}

// Ink for three pages: 0 = screen annotations, 1 = white board, 2 = black board.
final class InkView: NSView, NSTextViewDelegate {
    var pages: [[Stroke]] = [[], [], []]
    var bubbles: [[Bubble]] = [[], [], []]
    var bubbleStyle: () -> (NSColor, CGFloat) = { (.red, 16) }
    var onBubbleEnd: () -> Void = {}
    private var editor: NSTextView?
    private var editorTop = CGPoint.zero // view coordinates
    var history: [[Edit]] = [[], [], []]
    var page = 0 { didSet { needsDisplay = true } }
    var tool = Tool.pen
    var newStroke: () -> Stroke = { Stroke(color: .red, width: 4, highlighter: false, pressure: false) }
    // Ink lives in coordinates of the unzoomed screen. While zoomed, content point c is shown at (c - zoomOrigin) * zoomScale.
    var zoomScale: CGFloat = 1, zoomOrigin = CGPoint.zero
    var cursor = NSCursor.arrow
    private var current: Stroke?
    private var erased: [Stroke] = []

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        if trackingAreas.isEmpty {
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
        }
    }
    // Tracking events keep coming while the window ignores the mouse (outside pen mode),
    // so only show the tool cursor while the overlay actually takes input.
    private func showCursor() { if window?.ignoresMouseEvents == false { cursor.set() } }
    override func mouseEntered(with e: NSEvent) { showCursor() }
    override func mouseMoved(with e: NSEvent) { showCursor() }
    override func cursorUpdate(with e: NSEvent) { showCursor() }

    func content(_ v: CGPoint) -> CGPoint {
        CGPoint(x: v.x / zoomScale + zoomOrigin.x, y: v.y / zoomScale + zoomOrigin.y)
    }

    private func point(_ e: NSEvent) -> CGPoint { content(convert(e.locationInWindow, from: nil)) }
    private func pressure(_ e: NSEvent) -> CGFloat { e.subtype == .tabletPoint ? CGFloat(e.pressure) : 0.5 }

    override func mouseDown(with e: NSEvent) {
        cursor.set()
        if editor != nil { endBubble(commit: true); return } // clicking elsewhere confirms the note
        if tool == .text { beginBubble(convert(e.locationInWindow, from: nil)); return }
        if tool == .eraser { erased = []; erase(at: point(e)); return }
        let s = newStroke()
        s.add(point(e), pressure(e))
        current = s
        pages[page].append(s)
        dirty(s)
    }

    override func mouseDragged(with e: NSEvent) {
        if tool == .eraser { erase(at: point(e)); return }
        guard let s = current else { return }
        s.add(point(e), pressure(e))
        dirty(s)
    }

    override func mouseUp(with e: NSEvent) {
        if tool == .eraser { endErase(); return }
        if let s = current { history[page].append(Edit(added: [s])) }
        current = nil
    }

    // Redraw only around the newest points of a stroke being drawn.
    private func dirty(_ s: Stroke) {
        let tail = s.pts.suffix(3)
        var r = CGRect(origin: tail.first!, size: .zero)
        for p in tail { r = r.union(CGRect(origin: p, size: .zero)) }
        let pad = s.width * 2 + 2
        r = r.insetBy(dx: -pad, dy: -pad)
        setNeedsDisplay(NSRect(x: (r.minX - zoomOrigin.x) * zoomScale, y: (r.minY - zoomOrigin.y) * zoomScale,
                               width: r.width * zoomScale, height: r.height * zoomScale))
    }

    func erase(at p: CGPoint) {
        let hit = pages[page].filter { $0.hits(p, 6 / zoomScale) }
        if hit.isEmpty { return }
        pages[page].removeAll { s in hit.contains { $0 === s } }
        erased += hit
        needsDisplay = true
    }

    func endErase() {
        if !erased.isEmpty { history[page].append(Edit(removed: erased)) }
        erased = []
    }

    func undo() {
        guard let e = history[page].popLast() else { return }
        pages[page].removeAll { s in e.added.contains { $0 === s } }
        pages[page] += e.removed
        bubbles[page].insert(contentsOf: e.bubbles, at: 0) // beneath any added since
        needsDisplay = true
    }

    // Removes every stroke and speech bubble of the page as one step, so undo brings them back.
    func clear() {
        guard !pages[page].isEmpty || !bubbles[page].isEmpty else { return }
        history[page].append(Edit(removed: pages[page], bubbles: bubbles[page]))
        pages[page] = []
        bubbles[page] = []
        needsDisplay = true
    }

    // ---------- speech bubbles (not undone one by one; Clear removes them, and undoing it brings them back) ----------

    func beginBubble(_ v: CGPoint) {
        let (color, size) = bubbleStyle()
        let tv = NSTextView(frame: NSRect(x: v.x, y: v.y, width: 120, height: 0))
        tv.font = .systemFont(ofSize: size * zoomScale)
        tv.textColor = .black
        tv.backgroundColor = .white
        tv.insertionPointColor = .black
        tv.isRichText = false
        tv.allowsUndo = true
        tv.textContainerInset = NSSize(width: 4, height: 6)
        tv.isVerticallyResizable = false
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.containerSize = NSSize(width: 600 * zoomScale, height: CGFloat.greatestFiniteMagnitude)
        tv.wantsLayer = true
        tv.layer?.borderColor = color.cgColor
        tv.layer?.borderWidth = 2
        tv.delegate = self
        editor = tv
        editorTop = v
        addSubview(tv)
        fitEditor()
        window?.makeKey()
        window?.makeFirstResponder(tv)
    }

    // Grows with the text, keeping its top-left at the click.
    private func fitEditor() {
        guard let tv = editor, let lm = tv.layoutManager, let tc = tv.textContainer else { return }
        lm.ensureLayout(for: tc)
        let u = lm.usedRect(for: tc).union(lm.extraLineFragmentRect)
        let w = max(120, ceil(u.width) + 8 + tv.font!.pointSize), h = ceil(u.height) + 12
        tv.frame = NSRect(x: editorTop.x, y: editorTop.y - h, width: w, height: h)
    }

    func endBubble(commit: Bool) {
        guard let tv = editor else { return }
        editor = nil
        let t = tv.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if commit && !t.isEmpty {
            let (color, size) = bubbleStyle()
            bubbles[page].append(Bubble(text: t, at: content(editorTop), color: color, size: size))
            needsDisplay = true
        }
        tv.removeFromSuperview()
        onBubbleEnd()
    }

    func textDidChange(_ n: Notification) { fitEditor() }
    func textDidEndEditing(_ n: Notification) { endBubble(commit: true) }

    // Enter confirms (Shift+Enter adds a line, Enter while an input method is composing just finishes the character), Esc cancels.
    func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
        if sel == #selector(NSResponder.cancelOperation(_:)) { endBubble(commit: false); return true }
        if sel == #selector(NSResponder.insertNewline(_:)) && !tv.hasMarkedText()
            && NSApp.currentEvent?.modifierFlags.contains(.shift) != true { endBubble(commit: true); return true }
        return false
    }

    override func draw(_ r: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.scaleBy(x: zoomScale, y: zoomScale)
        ctx.translateBy(x: -zoomOrigin.x, y: -zoomOrigin.y)
        // highlighter beneath the pen
        for s in pages[page] where s.highlighter { s.draw(ctx) }
        for s in pages[page] where !s.highlighter { s.draw(ctx) }
        for b in bubbles[page] { b.draw() }
    }
}
