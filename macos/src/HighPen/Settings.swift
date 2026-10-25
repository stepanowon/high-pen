import Cocoa

// ---------- settings (UserDefaults; missing or out-of-range values fall back to the default) ----------

enum Cfg {
    static let d = UserDefaults.standard
    static let palette = [0xFF3B30, 0xFF9500, 0xFFD60A, 0x34C759, 0x0A84FF, 0xBF5AF2, 0x000000, 0xFFFFFF].map(rgb)
    static let colorNames = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Black", "White"] // Lang keys
    static let black = 6, white = 7
    static let zoomFactors: [CGFloat] = [1.5, 2, 2.5]

    static func int(_ k: String, _ def: Int, _ r: ClosedRange<Int>) -> Int {
        d.object(forKey: k) == nil ? def : min(max(d.integer(forKey: k), r.lowerBound), r.upperBound)
    }
    static func num(_ k: String, _ def: Double, _ r: ClosedRange<Double>) -> Double {
        d.object(forKey: k) == nil ? def : min(max(d.double(forKey: k), r.lowerBound), r.upperBound)
    }
    static func flag(_ k: String, _ def: Bool) -> Bool { d.object(forKey: k) == nil ? def : d.bool(forKey: k) }

    static var penColor: Int { get { int("PenColor", 0, 0...7) } set { d.set(newValue, forKey: "PenColor") } }
    static var penSize: Double { get { num("PenSize", 4, 1...30) } set { d.set(newValue, forKey: "PenSize") } }
    static var pressure: Bool { get { flag("Pressure", true) } set { d.set(newValue, forKey: "Pressure") } }
    static var highlightColor: Int { get { int("HighlightColor", 2, 0...7) } set { d.set(newValue, forKey: "HighlightColor") } }
    static var highlightSize: Double { get { num("HighlightSize", 20, 5...60) } set { d.set(newValue, forKey: "HighlightSize") } }
    static var spotColor: Int { get { int("SpotColor", 2, 0...7) } set { d.set(newValue, forKey: "SpotColor") } }
    static var spotSize: Double { get { num("SpotSize", 70, 20...200) } set { d.set(newValue, forKey: "SpotSize") } }
    static var spotOn: Bool { get { flag("SpotOn", true) } set { d.set(newValue, forKey: "SpotOn") } }
    static var zoomIndex: Int { get { int("ZoomIndex", 1, 0...2) } set { d.set(newValue, forKey: "ZoomIndex") } }
    // The chosen monitor is remembered by display UUID, so it survives monitors being reordered. While it is
    // disconnected HighPen uses the main monitor, and returns to it once it is connected again.
    static var monitor: Int {
        get {
            let all = NSScreen.screens
            if let u = d.string(forKey: "MonitorUUID") { return all.firstIndex { displayUUID($0) == u } ?? 0 }
            let m = int("Monitor", 0, 0...63) // saved before the UUID was
            return m < all.count ? m : 0
        }
        set { d.set(newValue, forKey: "Monitor"); d.set(displayUUID(screen(newValue)), forKey: "MonitorUUID") }
    }
    static var monitorChosen: Bool { d.string(forKey: "MonitorUUID") == displayUUID(screen(monitor)) }
    // toolbar offset from the top-left of the monitor's visible area, in points
    static var barX: Double { get { num("BarX", 20, 0...100_000) } set { d.set(newValue, forKey: "BarX") } }
    static var barY: Double { get { num("BarY", 20, 0...100_000) } set { d.set(newValue, forKey: "BarY") } }
    static var language: String? { get { d.string(forKey: "Language") } set { d.set(newValue, forKey: "Language") } }
    // Shortcuts changed from their defaults, by action id (Hotkey.saved, or "" = no shortcut).
    static var hotkeys: [String: String] { get { d.dictionary(forKey: "Hotkeys") as? [String: String] ?? [:] } set { d.set(newValue, forKey: "Hotkeys") } }
}
