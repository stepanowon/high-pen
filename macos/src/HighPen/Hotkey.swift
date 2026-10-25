import Cocoa
import Carbon.HIToolbox

// ---------- shortcuts (Carbon modifier mask + virtual key code) ----------

// A shortcut: Carbon modifier mask + virtual key code, with the key's printed name for display.
struct Hotkey {
    let mods: Int, key: Int, name: String

    static let fKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10",
        kVK_F11: "F11", kVK_F12: "F12", kVK_F13: "F13", kVK_F14: "F14", kVK_F15: "F15", kVK_F16: "F16", kVK_F17: "F17", kVK_F18: "F18", kVK_F19: "F19", kVK_F20: "F20",
    ]
    static let special: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Delete: "⌫", kVK_ForwardDelete: "⌦",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
        kVK_Home: "↖", kVK_End: "↘", kVK_PageUp: "⇞", kVK_PageDown: "⇟",
    ]

    init(mods: Int, key: Int, name: String) { self.mods = mods; self.key = key; self.name = name }

    init?(saved s: String) {
        let p = s.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard p.count == 3, let m = Int(p[0]), let k = Int(p[1]), !p[2].isEmpty else { return nil }
        self.init(mods: m, key: k, name: String(p[2]))
    }

    // A key press in the shortcut editor.
    init(event e: NSEvent) {
        let f = e.modifierFlags
        let m = (f.contains(.control) ? controlKey : 0) | (f.contains(.option) ? optionKey : 0)
            | (f.contains(.shift) ? shiftKey : 0) | (f.contains(.command) ? cmdKey : 0)
        let k = Int(e.keyCode)
        var n = Hotkey.fKeys[k] ?? Hotkey.special[k] ?? Hotkey.asciiName(k) ?? ""
        if n.isEmpty || n.unicodeScalars.first!.value < 0x20 { n = "#" + String(k) } // unprintable (keypad etc.)
        self.init(mods: m, key: k, name: n)
    }

    // The key's character on the ASCII-capable layout ("P" even while a Korean or Japanese input source is active).
    static func asciiName(_ keyCode: Int) -> String? {
        guard let src = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(src, kTISPropertyUnicodeKeyLayoutData),
              let bytes = CFDataGetBytePtr(Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue()) else { return nil }
        var dead: UInt32 = 0, len = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        guard UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                             OptionBits(kUCKeyTranslateNoDeadKeysBit), &dead, chars.count, &len, &chars) == noErr, len > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: len).uppercased()
    }

    var saved: String { String(mods) + ":" + String(key) + ":" + name }
    var text: String {
        (mods & controlKey != 0 ? "⌃" : "") + (mods & optionKey != 0 ? "⌥" : "")
            + (mods & shiftKey != 0 ? "⇧" : "") + (mods & cmdKey != 0 ? "⌘" : "") + name
    }
    func same(_ o: Hotkey) -> Bool { mods == o.mods && key == o.key }
}

struct HotkeyAction {
    let id: String, def: Hotkey
    let title: () -> String
    let run: () -> Void
}
