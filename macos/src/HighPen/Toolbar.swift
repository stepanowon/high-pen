import Cocoa

// ---------- toolbar (the column of tool buttons; dragging its header moves it) ----------

struct ToolbarButton {
    let id: String, symbol: String, title: String, tip: String, tint: NSColor
    let run: () -> Void

    init(_ id: String, _ symbol: String, _ title: String, _ tip: String, tint: NSColor = .white, _ run: @escaping () -> Void) {
        self.id = id; self.symbol = symbol; self.title = title; self.tip = tip; self.tint = tint; self.run = run
    }
}

// The edge of the visible area the bar lies along, as a row (free = upright, anywhere).
enum BarEdge: Int { case free, top, bottom }

// The header: dragging it moves the bar. Its arrow button still takes clicks.
final class DragView: NSView {
    var drag: () -> Void = {}
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func hitTest(_ p: NSPoint) -> NSView? {
        let v = super.hitTest(p)
        return v is NSButton || v == nil ? v : self
    }
    override func mouseDown(with e: NSEvent) { drag() }
}

@MainActor
final class Toolbar: NSObject {
    // the bar, and what is left of it collapsed: the arrow
    static let width: CGFloat = 84, arrowWidth: CGFloat = 28, buttonHeight: CGFloat = 40, headerHeight: CGFloat = 30
    // Upright each button is one row: a smaller icon, then its title to the right. The titles are labelSize unless
    // the longest in the language needs them smaller (down to minLabelSize) to fit.
    static let iconSize: CGFloat = 15, wideIconSize: CGFloat = 18, iconColumn: CGFloat = 24, rowPadding: CGFloat = 2, labelGap: CGFloat = 3
    static let labelSize: CGFloat = 10, minLabelSize: CGFloat = 8
    // titles that only show in some states
    static let otherTitles = ["WhiteBoard", "BlackBoard", "ZoomLocked", "Rectangle", "Ellipse"]
    // Lying along an edge the buttons show only their icons, to keep the bar low; the hints still name them.
    static let wideButton: CGFloat = 56, wideQuit: CGFloat = 44, wideHeight: CGFloat = 36
    // How far from the top or bottom of the visible area the pointer takes the bar onto that edge, and off it again,
    // so that the bar does not flip back and forth around one spot.
    static let edgeEnter: CGFloat = 30, edgeLeave: CGFloat = 60
    let window = Panel(level: 3, clickThrough: false)
    var onMove: () -> Void = {}
    var onEdgeChange: () -> Void = {}
    private(set) var edge = BarEdge.free
    var horizontal: Bool { edge != .free }
    private let hints: Hints
    private var buttons: [(id: String, button: NSButton, width: NSLayoutConstraint, height: NSLayoutConstraint)] = []
    // per button: the title it was built with, the one it shows now, its hint, symbol and colour
    private var titles: [String: (base: String, now: String, tip: String, symbol: String, tint: NSColor)] = [:]
    private var root = NSStackView(), column = NSStackView()
    private let header = DragView()
    private var collapseBtn = NSButton(), name = NSTextField()
    private var headerWidth: NSLayoutConstraint?, headerHeightC: NSLayoutConstraint?
    private var collapsed = false
    // Upright at the right end of the visible area, the arrow is right of the title so that it stays in the corner when collapsed.
    private var arrowRight = false
    // The visible area of the selected monitor, read when the bar is placed or a drag starts.
    private var area = NSRect.zero
    private var labelFont = NSFont.systemFont(ofSize: Toolbar.labelSize)

    init(hints: Hints) {
        self.hints = hints
        super.init()
        header.drag = { [unowned self] in self.drag() }
    }

    func build(_ items: [ToolbarButton], collapseTip: String, onCollapse: @escaping () -> Void) {
        buttons = []
        titles = [:]
        header.subviews.forEach { $0.removeFromSuperview() }
        header.wantsLayer = true
        header.layer?.backgroundColor = rgb(0x4A522A).cgColor
        header.translatesAutoresizingMaskIntoConstraints = false
        if headerWidth == nil {
            headerWidth = header.widthAnchor.constraint(equalToConstant: Toolbar.width)
            headerHeightC = header.heightAnchor.constraint(equalToConstant: Toolbar.headerHeight)
            NSLayoutConstraint.activate([headerWidth!, headerHeightC!])
        }
        name = label("HighPen", size: 11)
        name.font = .systemFont(ofSize: 11, weight: .semibold)
        header.addSubview(name)
        collapseBtn = NSButton(image: NSImage(), target: nil, action: nil)
        collapseBtn.on { _ in onCollapse() }
        collapseBtn.isBordered = false
        collapseBtn.contentTintColor = .white
        collapseBtn.wantsLayer = true
        collapseBtn.layer?.backgroundColor = idleBg.cgColor
        hints.attach(collapseBtn, collapseTip)
        header.addSubview(collapseBtn)

        let col = NSStackView()
        col.spacing = 1
        for item in items { col.addArrangedSubview(makeButton(item)) }
        column = col
        fitLabels(items.map(\.title) + Toolbar.otherTitles.map(Lang.t))

        root = NSStackView(views: [header, col])
        root.spacing = 1
        root.wantsLayer = true
        root.layer?.backgroundColor = lineColor.cgColor
        window.contentView = root
        applyOrientation()
    }

    private func makeButton(_ item: ToolbarButton) -> NSButton {
        let b = NSButton(image: NSImage(), target: nil, action: nil)
        let run = item.run, id = item.id
        b.on { _ in run() }
        b.isBordered = false
        b.imagePosition = .imageOnly
        b.setAccessibilityLabel(item.title)
        b.wantsLayer = true
        b.layer?.backgroundColor = idleBg.cgColor
        titles[id] = (item.title, item.title, item.tip, item.symbol, item.tint)
        hints.attach(b) { [unowned self] in self.tip(id) }
        b.translatesAutoresizingMaskIntoConstraints = false
        let w = b.widthAnchor.constraint(equalToConstant: Toolbar.width), h = b.heightAnchor.constraint(equalToConstant: Toolbar.buttonHeight)
        NSLayoutConstraint.activate([w, h])
        buttons.append((id, b, w, h))
        return b
    }

    // The titles share one size, the largest up to labelSize (in half points) at which the longest fits the row.
    private func fitLabels(_ all: [String]) {
        let room = Toolbar.width - 2 * Toolbar.rowPadding - Toolbar.iconColumn - Toolbar.labelGap - 1
        let font = NSFont.systemFont(ofSize: Toolbar.labelSize)
        let longest = all.map { NSAttributedString(string: $0, attributes: [.font: font]).size().width }.max() ?? 0
        let size = longest <= room ? Toolbar.labelSize : max(Toolbar.minLabelSize, (Toolbar.labelSize * room / longest * 2).rounded(.down) / 2)
        labelFont = .systemFont(ofSize: size)
    }

    // Along an edge the buttons have no titles, so a title that changed (Locked, the board) leads the hint.
    private func tip(_ id: String) -> String {
        guard let t = titles[id] else { return "" }
        return horizontal && t.now != t.base ? t.now + "\n" + t.tip : t.tip
    }

    // The button's face: the icon, with the title right of it when upright. Drawn as one image so that switching
    // orientation only swaps images: a button whose own title comes and goes leaves AppKit objects behind each time.
    private func showFace(_ id: String) {
        guard let t = titles[id], let b = buttons.first(where: { $0.id == id })?.button else { return }
        let symbol = NSImage(systemSymbolName: t.symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: horizontal ? Toolbar.wideIconSize : Toolbar.iconSize, weight: .regular)
                .applying(.init(paletteColors: [.white, t.tint]))) ?? NSImage()
        guard !horizontal else { b.image = symbol; return }
        let title = NSAttributedString(string: t.now, attributes: [.foregroundColor: NSColor.white, .font: labelFont])
        b.image = NSImage(size: NSSize(width: Toolbar.width, height: Toolbar.buttonHeight), flipped: false) { r in
            let s = symbol.size, ts = title.size(), x = Toolbar.rowPadding + Toolbar.iconColumn + Toolbar.labelGap
            symbol.draw(in: NSRect(x: Toolbar.rowPadding + (Toolbar.iconColumn - s.width) / 2, y: (r.height - s.height) / 2, width: s.width, height: s.height))
            title.draw(at: NSPoint(x: x, y: (r.height - ts.height) / 2))
            return true
        }
    }

    func highlight(_ id: String, _ on: Bool) {
        buttons.first { $0.id == id }?.button.layer?.backgroundColor = (on ? activeBg : idleBg).cgColor
    }

    func setTitle(_ id: String, _ t: String, symbol: String? = nil) {
        guard titles[id]?.now != t || symbol.map({ $0 != titles[id]?.symbol }) == true else { return }
        titles[id]?.now = t
        if let s = symbol { titles[id]?.symbol = s }
        showFace(id)
    }

    // Collapsed, only the arrow is left, so the title no longer covers what is underneath.
    func setCollapsed(_ c: Bool) {
        collapsed = c
        column.isHidden = c
        name.isHidden = c
        headerWidth?.constant = c ? Toolbar.arrowWidth : Toolbar.width
        layoutHeader()
    }

    // Upright: a column of rows, icon and title. Along an edge: a row of icons, with no border on the screen's edge
    // (a pointer thrown against it lands on the buttons).
    private func applyOrientation() {
        let h = horizontal
        root.orientation = h ? .horizontal : .vertical
        column.orientation = root.orientation
        root.edgeInsets = NSEdgeInsets(top: edge == .top ? 0 : 1, left: 1, bottom: edge == .bottom ? 0 : 1, right: 1)
        headerHeightC?.constant = h ? Toolbar.wideHeight : Toolbar.headerHeight
        for b in buttons {
            b.width.constant = !h ? Toolbar.width : b.id == "Quit" ? Toolbar.wideQuit : Toolbar.wideButton
            b.height.constant = h ? Toolbar.wideHeight : Toolbar.buttonHeight
            showFace(b.id)
        }
        layoutHeader()
    }

    private func layoutHeader() {
        let hh = horizontal ? Toolbar.wideHeight : Toolbar.headerHeight
        let right = arrowRight && !horizontal
        collapseBtn.frame = NSRect(x: right && !collapsed ? Toolbar.width - Toolbar.arrowWidth : 0, y: 0, width: Toolbar.arrowWidth, height: hh)
        name.frame = NSRect(x: right ? 6 : Toolbar.arrowWidth + 6, y: (hh - 16) / 2, width: Toolbar.width - Toolbar.arrowWidth - 6, height: 16)
        // the arrow points the way the bar goes when clicked
        let open = collapsed != right
        collapseBtn.image = NSImage(systemSymbolName: open ? "chevron.right" : "chevron.left", accessibilityDescription: Lang.t("Collapse"))
    }

    private func setEdge(_ e: BarEdge) {
        guard e != edge else { return }
        edge = e
        applyOrientation()
        onEdgeChange()
    }

    // The bar's width when not collapsed.
    private var expandedWidth: CGFloat {
        guard horizontal else { return Toolbar.width + 2 }
        let n = CGFloat(buttons.count)
        return Toolbar.width + (n - 1) * (Toolbar.wideButton + 1) + Toolbar.wideQuit + 1 + 2
    }

    private func fitsAlongEdge() -> Bool {
        let e = edge
        edge = .top // the width along an edge
        defer { edge = e }
        return expandedWidth <= area.width
    }

    // At the saved offset from the top-left of the selected monitor, kept inside it, along the saved edge
    // if it fits on this monitor.
    func place() {
        area = screen(Cfg.monitor).visibleFrame
        let e = BarEdge(rawValue: Cfg.barEdge) ?? .free
        setEdge(e != .free && fitsAlongEdge() ? e : .free)
        put(left: area.minX + Cfg.barX, top: area.maxY - Cfg.barY)
    }

    // left: of the bar when not collapsed; top: of the bar. Both are kept inside the visible area.
    private func put(left: CGFloat, top: CGFloat) {
        let s = root.fittingSize, ew = expandedWidth
        let l = min(max(left, area.minX), area.maxX - ew)
        if !collapsed {
            let r = !horizontal && l + ew >= area.maxX
            if r != arrowRight { arrowRight = r; layoutHeader() }
        }
        let t = edge == .top ? area.maxY : edge == .bottom ? area.minY + s.height : min(max(top, area.minY + s.height), area.maxY)
        window.setFrame(NSRect(x: collapsed && arrowRight ? l + ew - s.width : l, y: t - s.height, width: s.width, height: s.height), display: true)
    }

    // Follows the pointer until the button is let go. Near the top or bottom of the visible area the bar lies along it;
    // an upright bar against the left or right end stays upright, so it can slide along that side into a corner.
    private func drag() {
        guard !collapsed else { return }
        area = screen(Cfg.monitor).visibleFrame
        let start = NSEvent.mouseLocation, fits = fitsAlongEdge()
        var grab = CGPoint(x: start.x - window.frame.minX, y: window.frame.maxY - start.y) // from the top-left
        var moved = false
        while let e = NSApp.nextEvent(matching: [.leftMouseDragged, .leftMouseUp], until: .distantFuture, inMode: .eventTracking, dequeue: true) {
            let p = NSEvent.mouseLocation
            moved = moved || p != start
            if moved {
                let left = p.x - grab.x
                let against = left <= area.minX || left + expandedWidth >= area.maxX
                var next = BarEdge.free
                if fits && !(edge == .free && against) {
                    if p.y > area.maxY - (edge == .top ? Toolbar.edgeLeave : Toolbar.edgeEnter) { next = .top }
                    else if p.y <= area.minY + (edge == .bottom ? Toolbar.edgeLeave : Toolbar.edgeEnter) { next = .bottom }
                }
                if next != edge {
                    setEdge(next)
                    // the upright bar's header is lower than the row: keep the pointer on it
                    grab.y = min(grab.y, (horizontal ? Toolbar.wideHeight : Toolbar.headerHeight) - 1)
                }
                put(left: p.x - grab.x, top: p.y + grab.y)
                onMove()
            }
            if e.type == .leftMouseUp { break }
        }
        guard moved else { return }
        Cfg.barX = window.frame.minX - area.minX
        Cfg.barY = area.maxY - window.frame.maxY
        Cfg.barEdge = edge.rawValue
    }
}
