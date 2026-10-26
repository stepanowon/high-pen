import Cocoa

// ---------- toolbar (the column of tool buttons; dragging its background moves it) ----------

struct ToolbarButton {
    let id: String, symbol: String, title: String, tip: String, tint: NSColor
    let run: () -> Void

    init(_ id: String, _ symbol: String, _ title: String, _ tip: String, tint: NSColor = .white, _ run: @escaping () -> Void) {
        self.id = id; self.symbol = symbol; self.title = title; self.tip = tip; self.tint = tint; self.run = run
    }
}

@MainActor
final class Toolbar: NSObject, NSWindowDelegate {
    let window = Panel(level: 3, clickThrough: false)
    var onMove: () -> Void = {}
    private let hints: Hints
    private var buttons: [String: NSButton] = [:]
    private var column = NSStackView()
    private var collapseBtn = NSButton()
    private var name = NSTextField()
    private var headerWidth: NSLayoutConstraint?
    private var placing = false

    init(hints: Hints) {
        self.hints = hints
        super.init()
        window.isMovableByWindowBackground = true
        window.delegate = self
    }

    func build(_ items: [ToolbarButton], collapseTip: String, onCollapse: @escaping () -> Void) {
        buttons = [:]
        // header: collapse arrow + drag area (the whole panel is draggable by its background).
        // The arrow is on the left so that, collapsed, it stays put.
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = rgb(0x4A522A).cgColor
        fixedSize(header, nil, 30)
        headerWidth = header.widthAnchor.constraint(equalToConstant: 84)
        headerWidth?.isActive = true
        name = label("HighPen", size: 11)
        name.font = .systemFont(ofSize: 11, weight: .semibold)
        name.frame = NSRect(x: 34, y: 7, width: 50, height: 16)
        header.addSubview(name)
        collapseBtn = NSButton(image: NSImage(), target: nil, action: nil)
        collapseBtn.on { _ in onCollapse() }
        collapseBtn.isBordered = false
        collapseBtn.contentTintColor = .white
        collapseBtn.wantsLayer = true
        collapseBtn.layer?.backgroundColor = idleBg.cgColor
        hints.attach(collapseBtn, collapseTip)
        collapseBtn.frame = NSRect(x: 0, y: 0, width: 28, height: 30)
        header.addSubview(collapseBtn)

        let col = NSStackView()
        col.orientation = .vertical
        col.spacing = 1
        for item in items { col.addArrangedSubview(makeButton(item)) }
        column = col

        let root = NSStackView(views: [header, col])
        root.orientation = .vertical
        root.spacing = 1
        root.edgeInsets = NSEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        root.wantsLayer = true
        root.layer?.backgroundColor = lineColor.cgColor
        window.contentView = root
    }

    private func makeButton(_ item: ToolbarButton) -> NSButton {
        let img = NSImage(systemSymbolName: item.symbol, accessibilityDescription: item.title)?
            .withSymbolConfiguration(.init(pointSize: 18, weight: .regular)) ?? NSImage()
        let b = NSButton(title: item.title, image: img, target: nil, action: nil)
        let run = item.run
        b.on { _ in run() }
        b.isBordered = false
        b.imagePosition = .imageAbove
        b.contentTintColor = item.tint
        b.attributedTitle = buttonTitle(item.title)
        b.wantsLayer = true
        b.layer?.backgroundColor = idleBg.cgColor
        hints.attach(b, item.tip)
        fixedSize(b, 84, 52)
        buttons[item.id] = b
        return b
    }

    private func buttonTitle(_ t: String) -> NSAttributedString {
        NSAttributedString(string: t, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 10)])
    }

    func highlight(_ id: String, _ on: Bool) {
        buttons[id]?.layer?.backgroundColor = (on ? activeBg : idleBg).cgColor
    }

    func setTitle(_ id: String, _ t: String) { buttons[id]?.attributedTitle = buttonTitle(t) }

    // Collapsed, only the arrow is left, so the title no longer covers what is underneath.
    func setCollapsed(_ c: Bool) {
        column.isHidden = c
        name.isHidden = c
        headerWidth?.constant = c ? 28 : 84
        collapseBtn.image = NSImage(systemSymbolName: c ? "chevron.right" : "chevron.left", accessibilityDescription: Lang.t("Collapse"))
    }

    // At the saved offset from the top-left of the selected monitor, kept inside it.
    func place() {
        guard let v = window.contentView else { return }
        let vf = screen(Cfg.monitor).visibleFrame
        let s = v.fittingSize
        let x = min(max(vf.minX + Cfg.barX, vf.minX), vf.maxX - s.width)
        let y = min(max(vf.maxY - Cfg.barY - s.height, vf.minY), vf.maxY - s.height)
        placing = true
        window.setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
        placing = false
    }

    func windowDidMove(_ n: Notification) {
        guard !placing else { return }
        let vf = screen(Cfg.monitor).visibleFrame
        Cfg.barX = window.frame.minX - vf.minX
        Cfg.barY = vf.maxY - window.frame.maxY
        onMove()
    }
}
