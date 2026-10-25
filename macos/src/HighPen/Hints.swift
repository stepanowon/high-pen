import Cocoa

// ---------- hover hint (name + shortcut beside the control) ----------

@MainActor
final class Hints {
    private let win = Panel(level: 4, clickThrough: true)
    private let text = NSTextField(wrappingLabelWithString: "")
    private weak var owner: NSView?
    // The area a hint beside window w must not cover (the settings panel next to the toolbar).
    var avoid: (NSWindow) -> NSRect? = { _ in nil }

    init() {
        let box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = panelBg.cgColor
        box.layer?.borderColor = activeBg.cgColor
        box.layer?.borderWidth = 1
        box.layer?.cornerRadius = 4
        text.textColor = .white
        text.font = .systemFont(ofSize: 12)
        text.preferredMaxLayoutWidth = 320
        text.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(text)
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            text.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
            text.topAnchor.constraint(equalTo: box.topAnchor, constant: 5),
            text.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -5),
        ])
        win.contentView = box
    }

    func attach(_ v: NSView, _ t: String) {
        v.onHover({ [unowned self, unowned v] in self.show(t, for: v) },
                  { [unowned self, unowned v] in if self.owner === v { self.hide() } }) // exits can arrive after the next enter
    }

    func hide() { win.orderOut(nil) }

    // Beside the control: to the right, or to the left when that would cover the avoided area or leave the monitor.
    private func show(_ t: String, for v: NSView) {
        guard let w = v.window else { return }
        owner = v
        text.stringValue = t
        let s = win.contentView!.fittingSize
        let r = w.convertToScreen(v.convert(v.bounds, to: nil))
        let vf = screen(Cfg.monitor).visibleFrame
        var f = NSRect(x: w.frame.maxX + 6, y: r.midY - s.height / 2, width: s.width, height: s.height)
        if f.maxX > vf.maxX || avoid(w)?.intersects(f) == true {
            f.origin.x = w.frame.minX - 6 - s.width
        }
        f.origin.y = min(max(f.minY, vf.minY), vf.maxY - s.height)
        win.setFrame(f, display: true)
        win.orderFrontRegardless()
    }
}
