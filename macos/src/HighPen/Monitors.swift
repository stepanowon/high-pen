import Cocoa

// ---------- monitors ----------

func screen(_ i: Int) -> NSScreen {
    let all = NSScreen.screens
    return i < all.count ? all[i] : all[0]
}

func displayID(_ s: NSScreen) -> CGDirectDisplayID {
    (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
}

// Stays the same for a monitor across reconnects and restarts, unlike its display ID or position in NSScreen.screens.
func displayUUID(_ s: NSScreen) -> String {
    guard let u = CGDisplayCreateUUIDFromDisplayID(displayID(s))?.takeRetainedValue() else { return "" }
    return CFUUIDCreateString(nil, u) as String
}
