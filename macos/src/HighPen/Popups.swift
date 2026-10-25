import Cocoa

// ---------- popups (toast, about box, and the dialog frame they share with the shortcut editor) ----------

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

// A bordered panel, centred on the selected monitor.
@MainActor
func dialog(_ content: NSView, keyable: Bool) -> Panel {
    let w = Panel(level: 4, clickThrough: false)
    w.keyable = keyable
    let box = NSStackView(views: [content])
    box.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
    box.wantsLayer = true
    box.layer?.backgroundColor = panelBg.cgColor
    box.layer?.borderColor = activeBg.cgColor
    box.layer?.borderWidth = 1
    w.contentView = box
    let s = box.fittingSize, vf = screen(Cfg.monitor).visibleFrame
    w.setFrame(NSRect(x: vf.midX - s.width / 2, y: vf.midY - s.height / 2, width: s.width, height: s.height), display: true)
    return w
}

func vstack(_ views: [NSView], spacing: CGFloat = 6) -> NSStackView {
    let v = NSStackView(views: views)
    v.orientation = .vertical
    v.alignment = .leading
    v.spacing = spacing
    return v
}

func heading(_ t: String) -> NSTextField {
    let l = label(t, size: 18)
    l.font = .systemFont(ofSize: 18, weight: .semibold)
    return l
}

// Short message at the bottom of the selected monitor; click closes it.
@MainActor
final class Toast {
    private var window: Panel?

    func show(_ text: String, seconds: Double?, click: (() -> Void)? = nil) {
        hide()
        let t = Panel(level: 4, clickThrough: false)
        let box = ClickView()
        box.wantsLayer = true
        box.layer?.backgroundColor = panelBg.cgColor
        box.layer?.borderColor = activeBg.cgColor
        box.layer?.borderWidth = 1
        let l = NSTextField(wrappingLabelWithString: text)
        l.textColor = .white
        l.font = .systemFont(ofSize: 13)
        l.preferredMaxLayoutWidth = 560
        l.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(l)
        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 14),
            l.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            l.topAnchor.constraint(equalTo: box.topAnchor, constant: 10),
            l.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -10),
        ])
        box.click = { [weak self, weak t] in
            click?()
            t?.orderOut(nil)
            if self?.window === t { self?.window = nil }
        }
        t.contentView = box
        let s = box.fittingSize
        let vf = screen(Cfg.monitor).visibleFrame
        t.setFrame(NSRect(x: vf.midX - s.width / 2, y: vf.minY + 40, width: s.width, height: s.height), display: true)
        t.orderFrontRegardless()
        window = t
        if let sec = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + sec) { [weak self, weak t] in
                t?.orderOut(nil)
                if self?.window === t { self?.window = nil }
            }
        }
    }

    func hide() { window?.orderOut(nil) }
}

@MainActor
final class AboutBox {
    private var window: Panel?
    var isOpen: Bool { window != nil }

    func toggle() {
        if let w = window { w.orderOut(nil); window = nil; return }
        let repo = "https://github.com/stepanowon/high-pen"
        func row(_ name: String, _ value: String, _ url: String?) -> NSView {
            let n = label(name, color: .gray)
            fixedSize(n, 80, nil)
            var v: NSView = label(value)
            if let u = url {
                let b = NSButton(title: value, target: nil, action: nil)
                b.isBordered = false
                b.attributedTitle = NSAttributedString(string: value, attributes: [.foregroundColor: rgb(0x7FB2FF), .font: NSFont.systemFont(ofSize: 12)])
                b.on { _ in NSWorkspace.shared.open(URL(string: u)!) }
                v = b
            }
            let r = NSStackView(views: [n, v])
            r.spacing = 0
            return r
        }
        let tagline = label(Lang.t("Tagline"), color: .gray)
        let copyright = label("Copyright (c) 2026 StephenWon", size: 11, color: .gray)
        let close = NSButton(title: Lang.t("Close"), target: nil, action: nil)
        close.on { [unowned self] _ in self.toggle() }
        fixedSize(close, 300, nil)
        let col = vstack([heading("HighPen v" + appVersion), tagline,
                          row(Lang.t("Author"), "StephenWon", nil),
                          row(Lang.t("Email"), "stepanowon@gmail.com", "mailto:stepanowon@gmail.com"),
                          row(Lang.t("Website"), "github.com/stepanowon/high-pen", repo),
                          row(Lang.t("License"), "MIT License", repo + "/blob/main/LICENSE"),
                          copyright, close])
        col.setCustomSpacing(12, after: tagline)
        col.setCustomSpacing(14, after: copyright)
        let w = dialog(col, keyable: true)
        window = w
        w.makeKeyAndOrderFront(nil)
    }
}
