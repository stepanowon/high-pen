import Cocoa

// ---------- mouse spot (a translucent circle that follows the pointer) ----------

final class SpotView: NSView {
    var color = NSColor.yellow, opacity: CGFloat = 0.4
    override func draw(_ r: NSRect) {
        color.withAlphaComponent(opacity).setFill()
        NSBezierPath(ovalIn: bounds).fill()
    }
}

@MainActor
final class Spot {
    let window = Panel(level: 2, clickThrough: true)
    private let view = SpotView()
    private var timer: Timer?
    // where the pointer appears (it can be drawn in the zoomed image)
    var toShown: (CGPoint) -> CGPoint = { $0 }

    init() { window.contentView = view }

    // Applies the saved colour, size and on/off.
    func apply() {
        let s = Cfg.spotSize
        view.color = Cfg.palette[Cfg.spotColor]
        view.opacity = Cfg.spotOpacity / 100
        view.needsDisplay = true
        window.setContentSize(NSSize(width: s, height: s))
        if Cfg.spotOn {
            move()
            window.orderFrontRegardless()
            if timer == nil { timer = repeatingTimer(1.0 / 60) { [weak self] in self?.move() } }
        } else {
            window.orderOut(nil)
            timer?.invalidate()
            timer = nil
        }
    }

    private func move() {
        let p = toShown(NSEvent.mouseLocation), s = window.frame.size
        let o = NSPoint(x: p.x - s.width / 2, y: p.y - s.height / 2)
        if o != window.frame.origin { window.setFrameOrigin(o) }
    }
}
