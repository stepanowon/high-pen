import Cocoa
import Carbon.HIToolbox

// ---------- global hotkeys (registration with Carbon, and the shortcuts saved in the settings) ----------

// Carbon calls a plain C function, so the actions it runs are kept here by hotkey id.
private var hotkeyRun: [UInt32: () -> Void] = [:]
private let signature = OSType(0x4850_454E) // 'HPEN'

@MainActor
final class Hotkeys {
    let actions: [HotkeyAction]
    private(set) var failed: [String] = [] // shortcuts another app already owns
    private var refs: [EventHotKeyRef] = []

    init(_ actions: [HotkeyAction]) { self.actions = actions }

    func start() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            hotkeyRun[id.id]?()
            return noErr
        }, 1, &spec, nil, nil)
        register()
    }

    // The action's current shortcut (nil = none).
    func current(_ id: String) -> Hotkey? {
        let def = actions.first { $0.id == id }?.def
        guard let s = Cfg.hotkeys[id] else { return def }
        return s.isEmpty ? nil : Hotkey(saved: s) ?? def
    }

    func combo(_ id: String) -> String { current(id)?.text ?? "" }
    func tip(_ text: String, _ id: String) -> String {
        let c = combo(id)
        return c.isEmpty ? text : text + "   " + c
    }

    var failureNote: String? { failed.isEmpty ? nil : Lang.t("HotkeyFail") + "\n" + failed.joined(separator: ", ") }

    func unregister() {
        for r in refs { UnregisterEventHotKey(r) }
        refs = []
        hotkeyRun = [:]
    }

    func register() {
        unregister()
        failed = []
        for (n, a) in actions.enumerated() {
            guard let h = current(a.id) else { continue }
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: signature, id: UInt32(n + 1))
            if RegisterEventHotKey(UInt32(h.key), UInt32(h.mods), id, GetApplicationEventTarget(), 0, &ref) == noErr, let r = ref {
                refs.append(r)
                hotkeyRun[id.id] = a.run
            } else {
                failed.append(h.text)
            }
        }
    }

    // Whether another app already owns the combination (registered briefly under a spare id).
    func available(_ h: Hotkey) -> Bool {
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: signature, id: 0xBFFF)
        guard RegisterEventHotKey(UInt32(h.key), UInt32(h.mods), id, GetApplicationEventTarget(), 0, &ref) == noErr, let r = ref else { return false }
        UnregisterEventHotKey(r)
        return true
    }

    // The other action that already uses the combination, if any.
    func owner(of h: Hotkey, except i: Int) -> HotkeyAction? {
        actions.indices.first { $0 != i && current(actions[$0].id)?.same(h) == true }.map { actions[$0] }
    }

    // Saves a new shortcut for action i (nil = none); only changes from the default are stored.
    func set(_ i: Int, _ h: Hotkey?) {
        let a = actions[i]
        if let h = h, h.same(a.def) { Cfg.hotkeys[a.id] = nil } else { Cfg.hotkeys[a.id] = h?.saved ?? "" }
    }

    func resetAll() { Cfg.hotkeys = [:] }
}
