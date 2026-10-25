import Cocoa

// ---------- mouse spot (a translucent circle that follows the pointer) ----------

final class SpotView: NSView {
    var color = NSColor.yellow
    override func draw(_ r: NSRect) {
        color.withAlphaComponent(0.4).setFill()
        NSBezierPath(ovalIn: bounds).fill()
    }
}

@MainActor
final class Spot {
    let window = Panel(level: 2, clickThrough: true)
    private let view = SpotView()
    private var timer: Timer?

    init() { window.contentView = view }

    // Applies the saved colour, size and on/off.
    func apply() {
        let s = Cfg.spotSize
        view.color = Cfg.palette[Cfg.spotColor]
        view.needsDisplay = true
        window.setContentSize(NSSize(width: s, height: s))
        if Cfg.spotOn {
            move()
            window.orderFrontRegardless()
            if timer == nil {
                let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.move() } }
                RunLoop.main.add(t, forMode: .common)
                timer = t
            }
        } else {
            window.orderOut(nil)
            timer?.invalidate()
            timer = nil
        }
    }

    private func move() {
        let p = NSEvent.mouseLocation, s = window.frame.size
        let o = NSPoint(x: p.x - s.width / 2, y: p.y - s.height / 2)
        if o != window.frame.origin { window.setFrameOrigin(o) }
    }
}
