import Cocoa

// ---------- show clicks (an expanding ring where a mouse button is pressed) ----------

// A click-through window over the selected monitor that draws the rings. Mouse presses in other apps arrive
// through a global event monitor (no extra permission needed for mouse buttons), presses on HighPen's own
// windows through a local one. The monitors are only installed while click display is on.
@MainActor
final class Clicks {
    let window = Panel(level: 2, clickThrough: true)
    private let view = NSView()
    private var monitors: [Any] = []
    // false while every press is a pen stroke
    var allowed: () -> Bool = { true }

    init() {
        view.wantsLayer = true
        window.contentView = view
    }

    func place(_ frame: NSRect) { window.setFrame(frame, display: false) }

    // Applies the saved on/off.
    func apply() {
        if Cfg.showClicks && monitors.isEmpty {
            let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]
            if let g = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] e in
                let left = e.type == .leftMouseDown
                MainActor.assumeIsolated { self?.ripple(left: left) }
            }) { monitors.append(g) }
            if let l = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] e in
                let left = e.type == .leftMouseDown
                MainActor.assumeIsolated { self?.ripple(left: left) }
                return e
            }) { monitors.append(l) }
            window.orderFrontRegardless()
        } else if !Cfg.showClicks && !monitors.isEmpty {
            monitors.forEach(NSEvent.removeMonitor)
            monitors = []
            window.orderOut(nil)
        }
    }

    // Solid ring for the left button, dashed for the right, in the spot colour.
    private func ripple(left: Bool) {
        let p = NSEvent.mouseLocation, f = window.frame
        guard allowed(), f.contains(p), let root = view.layer else { return }
        let size = (Cfg.spotOn ? Cfg.spotSize : 0) + 60 // grows past the spot so it is not hidden behind it
        let ring = CAShapeLayer()
        ring.frame = CGRect(x: p.x - f.minX - size / 2, y: p.y - f.minY - size / 2, width: size, height: size)
        ring.path = CGPath(ellipseIn: ring.bounds.insetBy(dx: 1.5, dy: 1.5), transform: nil)
        ring.fillColor = nil
        ring.strokeColor = Cfg.palette[Cfg.spotColor].cgColor
        ring.lineWidth = 3
        if !left { ring.lineDashPattern = [6, 4.5] }
        ring.opacity = 0
        root.addSublayer(ring)
        CATransaction.begin()
        CATransaction.setCompletionBlock { ring.removeFromSuperlayer() }
        let grow = CABasicAnimation(keyPath: "transform.scale")
        grow.fromValue = 0.2
        grow.toValue = 1
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let g = CAAnimationGroup()
        g.animations = [grow, fade]
        g.duration = 0.45
        ring.add(g, forKey: nil)
        CATransaction.commit()
    }
}
