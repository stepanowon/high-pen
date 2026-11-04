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
    bordered(box)
    w.contentView = box
    let s = box.fittingSize, vf = screen(Cfg.monitor).visibleFrame
    w.setFrame(NSRect(x: vf.midX - s.width / 2, y: vf.midY - s.height / 2, width: s.width, height: s.height), display: true)
    return w
}

// One popup window at a time, made anew each time it opens and let go when it closes.
@MainActor
class Popup {
    private(set) var window: Panel?
    var isOpen: Bool { window != nil }

    // Shows w in place of the one open; key: takes the keyboard (dialogs) or leaves it with the app in use.
    func present(_ w: Panel, key: Bool) {
        window?.orderOut(nil)
        window = w
        if key { w.makeKeyAndOrderFront(nil) } else { w.orderFrontRegardless() }
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }

    // Closes w only if it is still the one shown (a timer or click of a popup already replaced).
    func close(_ w: Panel?) { if let w = w, w === window { close() } }
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
final class Toast: Popup {
    func show(_ text: String, seconds: Double?, click: (() -> Void)? = nil) {
        let t = Panel(level: 4, clickThrough: false)
        let box = ClickView()
        bordered(box)
        let l = wrapLabel(text, size: 13)
        l.preferredMaxLayoutWidth = 560
        pad(l, in: box, dx: 14, dy: 10)
        box.click = { [weak self, weak t] in
            click?()
            self?.close(t)
        }
        t.contentView = box
        let s = box.fittingSize
        let vf = screen(Cfg.monitor).visibleFrame
        t.setFrame(NSRect(x: vf.midX - s.width / 2, y: vf.minY + 40, width: s.width, height: s.height), display: true)
        present(t, key: false)
        if let sec = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + sec) { [weak self, weak t] in self?.close(t) }
        }
    }
}

@MainActor
final class AboutBox: Popup {
    func toggle() {
        if isOpen { close(); return }
        let repo = "https://github.com/stepanowon/high-pen"
        func row(_ name: String, _ value: String, _ url: String?) -> NSView {
            let n = label(name, color: .gray)
            fixedSize(n, 80, nil)
            var v: NSView = label(value)
            if let u = url {
                let b = NSButton(title: value, target: nil, action: nil)
                b.isBordered = false
                b.attributedTitle = NSAttributedString(string: value, attributes: [.foregroundColor: linkColor, .font: NSFont.systemFont(ofSize: 12)])
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
        close.on { [unowned self] _ in self.close() }
        fixedSize(close, 300, nil)
        let col = vstack([heading("HighPen v" + appVersion), tagline,
                          row(Lang.t("Author"), "StephenWon", nil),
                          row(Lang.t("Email"), "stepanowon@gmail.com", "mailto:stepanowon@gmail.com"),
                          row(Lang.t("Website"), "github.com/stepanowon/high-pen", repo),
                          row(Lang.t("License"), "MIT License", repo + "/blob/main/LICENSE"),
                          copyright, close])
        col.setCustomSpacing(12, after: tagline)
        col.setCustomSpacing(14, after: copyright)
        present(dialog(col, keyable: true), key: true)
    }
}

// Tells about a newer version and opens its release page.
@MainActor
final class UpdateBox: Popup {
    func show(_ u: UpdateInfo) {
        if let w = window { w.orderFrontRegardless(); return }
        let open = NSButton(title: Lang.t("UpdateDownload"), target: nil, action: nil)
        open.keyEquivalent = "\r"
        open.on { [unowned self] _ in NSWorkspace.shared.open(u.page); self.close() }
        let later = NSButton(title: Lang.t("UpdateLater"), target: nil, action: nil)
        later.on { [unowned self] _ in self.close() }
        let hint = wrapLabel(Lang.t("UpdateHint"), color: .gray, width: 360)
        let col = vstack([heading(Lang.t("UpdateTitle")),
                          wrapLabel(String(format: Lang.t("UpdateText"), u.version, appVersion), width: 360),
                          hint, NSStackView(views: [open, later])])
        col.setCustomSpacing(14, after: hint)
        present(dialog(col, keyable: true), key: true)
    }
}
