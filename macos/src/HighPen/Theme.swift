import Cocoa

// ---------- theme (colours, labels, tool cursors) ----------

func rgb(_ v: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let panelBg = rgb(0x2B2E33), activeBg = rgb(0x3E6FB0), idleBg = rgb(0x3A3D42), lineColor = rgb(0x141517)
let warnColor = rgb(0xFF9F0A), alertRed = rgb(0xFF453A), linkColor = rgb(0x7FB2FF)

func label(_ s: String, size: CGFloat = 12, color: NSColor = .white) -> NSTextField {
    let l = NSTextField(labelWithString: s)
    l.font = .systemFont(ofSize: size)
    l.textColor = color
    return l
}

// A label that wraps; width fixes it to that width.
func wrapLabel(_ s: String, size: CGFloat = 12, color: NSColor = .white, width: CGFloat? = nil) -> NSTextField {
    let l = NSTextField(wrappingLabelWithString: s)
    l.font = .systemFont(ofSize: size)
    l.textColor = color
    if let w = width { fixedSize(l, w, nil) }
    return l
}

// The panel background with a 1 pt border, as popups, hints and the settings panel have.
func bordered(_ v: NSView, border: NSColor = activeBg) {
    v.wantsLayer = true
    v.layer?.backgroundColor = panelBg.cgColor
    v.layer?.borderColor = border.cgColor
    v.layer?.borderWidth = 1
}

// Puts content inside box, inset by dx / dy, so the box takes the content's size.
func pad(_ content: NSView, in box: NSView, dx: CGFloat, dy: CGFloat) {
    content.translatesAutoresizingMaskIntoConstraints = false
    box.addSubview(content)
    NSLayoutConstraint.activate([
        content.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: dx),
        content.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -dx),
        content.topAnchor.constraint(equalTo: box.topAnchor, constant: dy),
        content.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -dy),
    ])
}

// A repeating timer on the main run loop that also fires while a menu or a drag is tracking.
@MainActor
func repeatingTimer(_ interval: TimeInterval, _ f: @escaping @MainActor () -> Void) -> Timer {
    let t = Timer(timeInterval: interval, repeats: true) { _ in MainActor.assumeIsolated { f() } }
    RunLoop.main.add(t, forMode: .common)
    return t
}

func fixedSize(_ v: NSView, _ w: CGFloat?, _ h: CGFloat?) {
    v.translatesAutoresizingMaskIntoConstraints = false
    if let w = w { v.widthAnchor.constraint(equalToConstant: w).isActive = true }
    if let h = h { v.heightAnchor.constraint(equalToConstant: h).isActive = true }
}

// Tool cursors: an outlined SF Symbol with the hot spot at its tip (bottom-left), or a ring centred on the eraser's reach.
func symbolCursor(_ symbol: String) -> NSCursor {
    let n: CGFloat = 28
    let img = NSImage(size: NSSize(width: n, height: n), flipped: false) { _ in
        let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        guard let black = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg.applying(.init(paletteColors: [.black]))),
              let white = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg.applying(.init(paletteColors: [.white]))) else { return false }
        let r = NSRect(origin: NSPoint(x: 2, y: 2), size: black.size)
        for dx in [-1.5, 0, 1.5] { for dy in [-1.5, 0, 1.5] { black.draw(in: r.offsetBy(dx: dx, dy: dy)) } }
        white.draw(in: r)
        return true
    }
    return NSCursor(image: img, hotSpot: NSPoint(x: 3, y: n - 3))
}

func ringCursor(_ d: CGFloat) -> NSCursor {
    let n = d + 4
    let img = NSImage(size: NSSize(width: n, height: n), flipped: false) { r in
        let o = NSBezierPath(ovalIn: r.insetBy(dx: 2, dy: 2))
        o.lineWidth = 3; NSColor.black.setStroke(); o.stroke()
        o.lineWidth = 1.5; NSColor.white.setStroke(); o.stroke()
        return true
    }
    return NSCursor(image: img, hotSpot: NSPoint(x: n / 2, y: n / 2))
}
