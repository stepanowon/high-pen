import Cocoa

// ---------- settings panel (beside the toolbar) ----------

// What the panel cannot do by itself: changes that reach beyond the saved value.
@MainActor
protocol SettingsPanelDelegate: AnyObject {
    func setMonitor(_ i: Int)
    func setLanguage(_ i: Int)
    func spotChanged()
    func zoomChanged()
    func showHotkeyEditor()
    func clicksChanged()
    func checkForUpdates()
}

@MainActor
final class SettingsPanel {
    let window = Panel(level: 3, clickThrough: false)
    private let hints: Hints
    private let hotkeys: Hotkeys
    private weak var delegate: SettingsPanelDelegate?
    private var penSwatches: NSSegmentedControl?, highlightSwatches: NSSegmentedControl?
    private var breakTitle = NSTextField(), breakBtns: [NSButton] = [], breakSlider = NSSlider()
    private var pressureBox: NSButton?, clicksBox: NSButton?
    // beside a bar lying along an edge: in columns. Changing it rearranges the groups without making them again
    // (making controls leaves AppKit bookkeeping behind each time).
    // The groups never leave their container, only their constraints change, and only when the panel is shown:
    // each time AppKit lays its controls out anew it keeps some bookkeeping (about 20 small objects) for good.
    var wide = false
    private var arrangedWide = false
    private var sections: [NSStackView] = []
    private var container = NSView(), versionSep = NSView(), version = NSTextField()
    private var placement: [NSLayoutConstraint] = []

    init(hints: Hints, hotkeys: Hotkeys, delegate: SettingsPanelDelegate) {
        self.hints = hints; self.hotkeys = hotkeys; self.delegate = delegate
    }

    func showPenColor(_ i: Int) { penSwatches?.selectedSegment = i }
    func showHighlightColor(_ i: Int) { highlightSwatches?.selectedSegment = i }
    // The checkboxes, after their shortcut changed them.
    func showSwitches() {
        pressureBox?.state = Cfg.pressure ? .on : .off
        clicksBox?.state = Cfg.showClicks ? .on : .off
    }

    // Updates the title, the preset buttons and the slider. A break already running keeps its length.
    private func showBreakMinutes(_ m: Int) {
        breakTitle.stringValue = String(format: Lang.t("BreakLength"), BreakTimes.label(m))
        for (b, p) in zip(breakBtns, BreakTimes.presets) { b.layer?.backgroundColor = (p == m ? activeBg : idleBg).cgColor }
        if Int(breakSlider.doubleValue.rounded()) != m { breakSlider.doubleValue = Double(m) }
    }

    private func setBreakMinutes(_ m: Int) {
        Cfg.breakMinutes = BreakTimes.clamp(m)
        showBreakMinutes(Cfg.breakMinutes)
    }

    // To the right of the toolbar, or to its left when it would run past the monitor edge. Beside a bar along
    // an edge: on the side away from that edge, by the end of the bar where the Settings button is.
    // ponytail: no scrolling; a monitor too low for the panel shows it cut off
    func place(beside bar: NSRect, edge: BarEdge, visible: Bool) {
        guard visible, let v = window.contentView else { window.orderOut(nil); return }
        if arrangedWide != wide { arrange() }
        let vf = screen(Cfg.monitor).visibleFrame
        let s = v.fittingSize
        var x = bar.maxX + s.width <= vf.maxX ? bar.maxX : bar.minX - s.width
        var y = max(bar.maxY - s.height, vf.minY)
        if edge != .free {
            x = min(max(bar.maxX - s.width, vf.minX), vf.maxX - s.width)
            y = edge == .top ? bar.minY - s.height : bar.maxY
        }
        window.setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
        window.orderFrontRegardless()
    }

    func rebuild() {
        // the groups of settings, in the order they stack in beside an upright bar
        sections = []
        func section() {
            let v = NSStackView()
            v.orientation = .vertical
            v.alignment = .leading
            v.spacing = 6
            v.addArrangedSubview(SettingsPanel.sep()) // shown between groups
            self.sections.append(v)
        }
        func add(_ v: NSView) { self.sections[self.sections.count - 1].addArrangedSubview(v) }
        func title(_ k: String) { add(label(Lang.t(k))) }
        section()

        title("Monitor")
        let mon = segments((1...NSScreen.screens.count).map { String($0) }, Cfg.monitor) { [unowned self] i in self.delegate?.setMonitor(i) }
        hints.attach(mon, hotkeys.tip(hotkeys.action("Monitor")!.title(), "Monitor"))
        add(mon)

        section()
        title("PenColor")
        let ps = swatches(Cfg.penColor) { Cfg.penColor = $0 }
        hints.attach(ps, (0..<Cfg.palette.count).map { hotkeys.tip(Lang.t(Cfg.colorNames[$0]), "Color" + String($0)) }.joined(separator: "\n"))
        penSwatches = ps
        add(ps)
        title("PenSize")
        add(slider(1, 30, Cfg.penSize) { Cfg.penSize = $0 })
        let pr = NSButton(checkboxWithTitle: Lang.t("Pressure"), target: nil, action: nil)
        pr.state = Cfg.pressure ? .on : .off
        hints.attach(pr, hotkeys.tip(Lang.t("Pressure"), "Pressure"))
        pr.on { c in Cfg.pressure = (c as! NSButton).state == .on }
        pressureBox = pr
        add(pr)

        section()
        title("HighlightColor")
        let hs = swatches(Cfg.highlightColor) { Cfg.highlightColor = $0 }
        highlightSwatches = hs
        add(hs)
        title("HighlightSize")
        add(slider(5, 60, Cfg.highlightSize) { Cfg.highlightSize = $0 })

        section()
        title("SpotColor")
        add(swatches(Cfg.spotColor) { [unowned self] in Cfg.spotColor = $0; self.delegate?.spotChanged() })
        title("SpotSize")
        add(slider(20, 200, Cfg.spotSize) { [unowned self] in Cfg.spotSize = $0; self.delegate?.spotChanged() })
        let cl = NSButton(checkboxWithTitle: Lang.t("ClickShow"), target: nil, action: nil)
        cl.state = Cfg.showClicks ? .on : .off
        hints.attach(cl, hotkeys.tip(Lang.t("ClickShow"), "Clicks"))
        cl.on { [unowned self] c in Cfg.showClicks = (c as! NSButton).state == .on; self.delegate?.clicksChanged() }
        clicksBox = cl
        add(cl)

        section()
        title("ZoomFactor")
        add(segments(Cfg.zoomFactors.map { String(format: "%gx", $0) }, Cfg.zoomIndex) { [unowned self] i in
            Cfg.zoomIndex = i
            self.delegate?.zoomChanged()
        })

        section()
        breakTitle = label("")
        add(breakTitle)
        breakBtns = BreakTimes.presets.map { m in
            let b = NSButton(title: BreakTimes.label(m), target: nil, action: nil)
            b.isBordered = false
            b.wantsLayer = true
            b.attributedTitle = NSAttributedString(string: b.title, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 11)])
            b.on { [unowned self] _ in self.setBreakMinutes(m) }
            fixedSize(b, 93, 24)
            return b
        }
        for i in stride(from: 0, to: breakBtns.count, by: 2) { // two to a row
            let row = NSStackView(views: Array(breakBtns[i..<min(i + 2, breakBtns.count)]))
            row.spacing = 4
            add(row)
        }
        breakSlider = slider(Double(BreakTimes.min), Double(BreakTimes.max), Double(Cfg.breakMinutes)) { [unowned self] v in
            let m = BreakTimes.clamp(Int(v.rounded()))
            if m != Cfg.breakMinutes { self.setBreakMinutes(m) }
        }
        breakSlider.numberOfTickMarks = (BreakTimes.max - BreakTimes.min) / BreakTimes.step + 1
        breakSlider.allowsTickMarkValuesOnly = true
        add(breakSlider)
        showBreakMinutes(Cfg.breakMinutes)

        section()
        title("Language")
        add(segments(Lang.names, Lang.cur) { [unowned self] i in self.delegate?.setLanguage(i) })

        section()
        let keys = NSButton(title: Lang.t("Hotkeys"), target: nil, action: nil)
        keys.on { [unowned self] _ in self.delegate?.showHotkeyEditor() }
        add(keys)
        if let note = hotkeys.failureNote {
            add(wrapLabel(note, size: 11, color: warnColor, width: 190))
        }
        let up = NSButton(title: Lang.t("UpdateCheck"), target: nil, action: nil)
        hints.attach(up, Lang.t("UpdateCheckTip"))
        up.on { [unowned self] _ in self.delegate?.checkForUpdates() }
        add(up)

        let c = NSView()
        bordered(c, border: lineColor)
        versionSep = SettingsPanel.sep()
        version = label("HighPen v" + appVersion, size: 11, color: .gray)
        for v in sections + [versionSep, version] {
            v.translatesAutoresizingMaskIntoConstraints = false
            c.addSubview(v)
        }
        container = c
        placement = []
        arrange()
        window.contentView = c
    }

    // Upright, the groups stack in one column; beside a bar along an edge they stand in four columns
    // (as indexes into the groups), each as wide as the upright panel.
    static let wideColumns = [[0, 4, 6], [1], [2, 5], [3, 7]]
    static let columnWidth: CGFloat = 190, gap: CGFloat = 16, inset: CGFloat = 10

    private func arrange() {
        guard !sections.isEmpty else { return }
        NSLayoutConstraint.deactivate(placement)
        placement = []
        arrangedWide = wide
        let c = container, cols = wide ? SettingsPanel.wideColumns : [Array(sections.indices)]
        for (i, col) in cols.enumerated() {
            var above: NSView?
            for j in col {
                let s = sections[j]
                // the separator stays in place (hiding it also leaves bookkeeping behind): first in a column it is
                // only made invisible, above the panel's inset
                s.arrangedSubviews[0].alphaValue = above == nil ? 0 : 1
                placement += [s.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: SettingsPanel.inset + CGFloat(i) * (SettingsPanel.columnWidth + SettingsPanel.gap)),
                              above == nil ? s.arrangedSubviews[1].topAnchor.constraint(equalTo: c.topAnchor, constant: SettingsPanel.inset)
                                           : s.topAnchor.constraint(equalTo: above!.bottomAnchor, constant: 6)]
                above = s
            }
            if let a = above { placement.append(versionSep.topAnchor.constraint(greaterThanOrEqualTo: a.bottomAnchor, constant: 6)) }
        }
        let n = CGFloat(cols.count)
        placement += [versionSep.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: SettingsPanel.inset),
                      version.topAnchor.constraint(equalTo: versionSep.bottomAnchor, constant: 6),
                      version.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: SettingsPanel.inset),
                      version.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -SettingsPanel.inset),
                      c.widthAnchor.constraint(equalToConstant: 2 * SettingsPanel.inset + n * SettingsPanel.columnWidth + (n - 1) * SettingsPanel.gap)]
        NSLayoutConstraint.activate(placement)
    }

    private static func sep() -> NSView {
        let b = NSBox()
        b.boxType = .separator
        fixedSize(b, columnWidth, nil)
        return b
    }

    private func swatches(_ sel: Int, _ pick: @escaping (Int) -> Void) -> NSSegmentedControl {
        let images = Cfg.palette.map { c in
            NSImage(size: NSSize(width: 14, height: 14), flipped: false) { r in
                let o = NSBezierPath(ovalIn: r.insetBy(dx: 1, dy: 1))
                c.setFill(); o.fill()
                NSColor.gray.setStroke(); o.stroke()
                return true
            }
        }
        let s = NSSegmentedControl(images: images, trackingMode: .selectOne, target: nil, action: nil)
        for i in 0..<images.count { s.setWidth(20, forSegment: i) }
        s.selectedSegment = sel
        s.on { c in pick((c as! NSSegmentedControl).selectedSegment) }
        return s
    }

    private func slider(_ min: Double, _ max: Double, _ v: Double, _ f: @escaping (Double) -> Void) -> NSSlider {
        let s = NSSlider(value: v, minValue: min, maxValue: max, target: nil, action: nil)
        s.on { c in f((c as! NSSlider).doubleValue) }
        fixedSize(s, 190, nil)
        return s
    }

    private func segments(_ labels: [String], _ sel: Int, _ f: @escaping (Int) -> Void) -> NSSegmentedControl {
        let s = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: nil)
        s.selectedSegment = sel
        s.on { c in f((c as! NSSegmentedControl).selectedSegment) }
        return s
    }
}
