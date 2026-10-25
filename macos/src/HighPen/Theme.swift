import Cocoa

// ---------- theme (colours, labels, tool cursors) ----------

func rgb(_ v: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

let panelBg = rgb(0x2B2E33), activeBg = rgb(0x3E6FB0), idleBg = rgb(0x3A3D42), lineColor = rgb(0x141517)

func label(_ s: String, size: CGFloat = 12, color: NSColor = .white) -> NSTextField {
    let l = NSTextField(labelWithString: s)
    l.font = .systemFont(ofSize: size)
    l.textColor = color
    return l
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
