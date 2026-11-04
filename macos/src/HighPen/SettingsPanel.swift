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

    // To the right of the toolbar, or to its left when it would run past the monitor edge.
    func place(beside bar: NSRect, visible: Bool) {
        guard visible, let v = window.contentView else { window.orderOut(nil); return }
        let vf = screen(Cfg.monitor).visibleFrame
        let s = v.fittingSize
        let x = bar.maxX + s.width <= vf.maxX ? bar.maxX : bar.minX - s.width
        let y = max(bar.maxY - s.height, vf.minY)
        window.setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
        window.orderFrontRegardless()
    }

    func rebuild() {
        let col = NSStackView()
        col.orientation = .vertical
        col.alignment = .leading
        col.spacing = 6
        col.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        bordered(col, border: lineColor)
        func title(_ k: String) { col.addArrangedSubview(label(Lang.t(k))) }
        func sep() {
            let b = NSBox()
            b.boxType = .separator
            fixedSize(b, 190, nil)
            col.addArrangedSubview(b)
        }

        title("Monitor")
        let mon = segments((1...NSScreen.screens.count).map { String($0) }, Cfg.monitor) { [unowned self] i in self.delegate?.setMonitor(i) }
        hints.attach(mon, hotkeys.tip(hotkeys.action("Monitor")!.title(), "Monitor"))
        col.addArrangedSubview(mon)
        sep()

        title("PenColor")
        let ps = swatches(Cfg.penColor) { Cfg.penColor = $0 }
        hints.attach(ps, (0..<Cfg.palette.count).map { hotkeys.tip(Lang.t(Cfg.colorNames[$0]), "Color" + String($0)) }.joined(separator: "\n"))
        penSwatches = ps
        col.addArrangedSubview(ps)
        title("PenSize")
        col.addArrangedSubview(slider(1, 30, Cfg.penSize) { Cfg.penSize = $0 })
        let pr = NSButton(checkboxWithTitle: Lang.t("Pressure"), target: nil, action: nil)
        pr.state = Cfg.pressure ? .on : .off
        hints.attach(pr, hotkeys.tip(Lang.t("Pressure"), "Pressure"))
        pr.on { c in Cfg.pressure = (c as! NSButton).state == .on }
        pressureBox = pr
        col.addArrangedSubview(pr)
        sep()

        title("HighlightColor")
        let hs = swatches(Cfg.highlightColor) { Cfg.highlightColor = $0 }
        highlightSwatches = hs
        col.addArrangedSubview(hs)
        title("HighlightSize")
        col.addArrangedSubview(slider(5, 60, Cfg.highlightSize) { Cfg.highlightSize = $0 })
        sep()

        title("SpotColor")
        col.addArrangedSubview(swatches(Cfg.spotColor) { [unowned self] in Cfg.spotColor = $0; self.delegate?.spotChanged() })
        title("SpotSize")
        col.addArrangedSubview(slider(20, 200, Cfg.spotSize) { [unowned self] in Cfg.spotSize = $0; self.delegate?.spotChanged() })
        let cl = NSButton(checkboxWithTitle: Lang.t("ClickShow"), target: nil, action: nil)
        cl.state = Cfg.showClicks ? .on : .off
        hints.attach(cl, hotkeys.tip(Lang.t("ClickShow"), "Clicks"))
        cl.on { [unowned self] c in Cfg.showClicks = (c as! NSButton).state == .on; self.delegate?.clicksChanged() }
        clicksBox = cl
        col.addArrangedSubview(cl)
        sep()

        title("ZoomFactor")
        col.addArrangedSubview(segments(Cfg.zoomFactors.map { String(format: "%gx", $0) }, Cfg.zoomIndex) { [unowned self] i in
            Cfg.zoomIndex = i
            self.delegate?.zoomChanged()
        })
        sep()

        breakTitle = label("")
        col.addArrangedSubview(breakTitle)
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
            col.addArrangedSubview(row)
        }
        breakSlider = slider(Double(BreakTimes.min), Double(BreakTimes.max), Double(Cfg.breakMinutes)) { [unowned self] v in
            let m = BreakTimes.clamp(Int(v.rounded()))
            if m != Cfg.breakMinutes { self.setBreakMinutes(m) }
        }
        breakSlider.numberOfTickMarks = (BreakTimes.max - BreakTimes.min) / BreakTimes.step + 1
        breakSlider.allowsTickMarkValuesOnly = true
        col.addArrangedSubview(breakSlider)
        showBreakMinutes(Cfg.breakMinutes)
        sep()

        title("Language")
        col.addArrangedSubview(segments(Lang.names, Lang.cur) { [unowned self] i in self.delegate?.setLanguage(i) })
        sep()

        let keys = NSButton(title: Lang.t("Hotkeys"), target: nil, action: nil)
        keys.on { [unowned self] _ in self.delegate?.showHotkeyEditor() }
        col.addArrangedSubview(keys)
        if let note = hotkeys.failureNote {
            col.addArrangedSubview(wrapLabel(note, size: 11, color: warnColor, width: 190))
        }
        let up = NSButton(title: Lang.t("UpdateCheck"), target: nil, action: nil)
        hints.attach(up, Lang.t("UpdateCheckTip"))
        up.on { [unowned self] _ in self.delegate?.checkForUpdates() }
        col.addArrangedSubview(up)
        sep()

        col.addArrangedSubview(label("HighPen v" + appVersion, size: 11, color: .gray))
        window.contentView = col
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
