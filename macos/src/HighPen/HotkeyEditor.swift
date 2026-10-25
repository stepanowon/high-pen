import Cocoa
import Carbon.HIToolbox

// ---------- shortcut editor ----------

// Lists every action with its shortcut. Click one, then press the new combination.
// HighPen's own shortcuts are released while the editor is open so pressing them reaches it.
@MainActor
final class HotkeyEditor {
    var onOpen: () -> Void = {}, onClose: () -> Void = {}
    private let hotkeys: Hotkeys
    private var window: Panel?
    private var waiting: Int? // index of the action whose new shortcut is being typed
    private var keyBoxes: [NSButton] = []
    private let status = NSTextField(wrappingLabelWithString: "")
    var isOpen: Bool { window != nil }

    init(hotkeys: Hotkeys) { self.hotkeys = hotkeys }

    func show() {
        if let w = window { w.makeKeyAndOrderFront(nil); return }
        hotkeys.unregister()
        waiting = nil
        keyBoxes = []
        let rows = vstack([], spacing: 4)
        for (i, a) in hotkeys.actions.enumerated() {
            let name = NSTextField(wrappingLabelWithString: a.title())
            name.textColor = .white
            name.font = .systemFont(ofSize: 12)
            fixedSize(name, 196, nil)
            let box = NSButton(title: "", target: nil, action: nil)
            box.isBordered = false
            box.wantsLayer = true
            box.on { [unowned self] _ in
                self.waiting = i
                self.status.textColor = .gray
                self.status.stringValue = Lang.t("HotkeyWaitHint")
                self.refresh()
            }
            fixedSize(box, 150, 26)
            keyBoxes.append(box)
            let r = NSStackView(views: [name, box])
            r.spacing = 8
            rows.addArrangedSubview(r)
        }
        rows.layoutSubtreeIfNeeded()
        let doc = FlippedView(frame: NSRect(origin: .zero, size: rows.fittingSize))
        rows.frame = doc.bounds
        doc.addSubview(rows)
        let scroll = NSScrollView()
        scroll.documentView = doc
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        fixedSize(scroll, rows.fittingSize.width + 16, min(440, rows.fittingSize.height))

        let hintText = label(Lang.t("HotkeyHint"), color: .gray)
        status.stringValue = ""
        status.font = .systemFont(ofSize: 12)
        fixedSize(status, 360, nil)
        let reset = NSButton(title: Lang.t("ResetDefaults"), target: nil, action: nil)
        reset.on { [unowned self] _ in
            self.hotkeys.resetAll()
            self.waiting = nil
            self.status.stringValue = ""
            self.refresh()
        }
        let close = NSButton(title: Lang.t("Close"), target: nil, action: nil)
        close.on { [unowned self] _ in self.close() }
        fixedSize(reset, 176, nil)
        fixedSize(close, 176, nil)
        let btns = NSStackView(views: [reset, close])
        btns.spacing = 8

        let w = dialog(vstack([heading(Lang.t("Hotkeys")), hintText, scroll, status, btns], spacing: 8), keyable: true)
        window = w
        refresh()
        onOpen()
        w.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.orderOut(nil)
        window = nil
        waiting = nil
        onClose()
    }

    // Every key press while the editor is open.
    func key(_ e: NSEvent) {
        let plain = e.modifierFlags.intersection([.control, .option, .shift, .command]).isEmpty
        let k = Int(e.keyCode)
        guard let i = waiting else {
            if plain && (k == kVK_Escape || k == kVK_Return) { close() }
            return
        }
        func warn(_ t: String) { status.textColor = rgb(0xFF9F0A); status.stringValue = t }
        if plain && k == kVK_Escape { waiting = nil; status.stringValue = ""; refresh(); return }
        if plain && (k == kVK_Delete || k == kVK_ForwardDelete) { status.stringValue = ""; assign(i, nil); return }
        let h = Hotkey(event: e)
        if h.mods & (controlKey | optionKey | cmdKey) == 0 && Hotkey.fKeys[k] == nil { warn(Lang.t("HotkeyNeedMod")); return }
        if let o = hotkeys.owner(of: h, except: i) { warn(String(format: Lang.t("HotkeyDup"), o.title())); return }
        if !hotkeys.available(h) { warn(Lang.t("HotkeyTaken")); return }
        status.stringValue = ""
        assign(i, h)
    }

    private func assign(_ i: Int, _ h: Hotkey?) {
        hotkeys.set(i, h)
        waiting = nil
        refresh()
    }

    private func refresh() {
        for (i, a) in hotkeys.actions.enumerated() {
            let c = hotkeys.combo(a.id)
            let t = i == waiting ? Lang.t("PressKeys") : (c.isEmpty ? Lang.t("NoKey") : c)
            keyBoxes[i].attributedTitle = NSAttributedString(string: t, attributes: [
                .foregroundColor: c.isEmpty && i != waiting ? NSColor.gray : NSColor.white, .font: NSFont.systemFont(ofSize: 12)])
            keyBoxes[i].layer?.backgroundColor = (i == waiting ? activeBg : idleBg).cgColor
        }
    }
}
