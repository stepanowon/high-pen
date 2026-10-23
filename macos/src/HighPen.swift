import Cocoa
import Carbon.HIToolbox
import CoreMedia
import ScreenCaptureKit

// ---------- strings (Korean / Japanese / English) ----------

enum Lang {
    static let codes = ["ko", "ja", "en"]
    static let names = ["한국어", "日本語", "English"]
    static var cur = 2

    static let text: [String: [String]] = [
        "Spot": ["스팟", "スポット", "Spot"],
        "MouseSpot": ["마우스 스팟", "マウススポット", "Mouse spot"],
        "Pen": ["펜", "ペン", "Pen"],
        "Eraser": ["지우개", "消しゴム", "Eraser"],
        "EraserTip": ["지우개 상태에서 단축키를 한 번 더 누르면 전체 삭제", "消しゴム中にもう一度ショートカットを押すと全消去", "Press the shortcut again while erasing to clear all"],
        "Highlighter": ["형광펜", "蛍光ペン", "Highlighter"],
        "HighlightColor": ["형광펜 색상", "蛍光ペンの色", "Highlighter color"],
        "HighlightSize": ["형광펜 두께", "蛍光ペンの太さ", "Highlighter width"],
        "Board": ["칠판", "ボード", "Board"],
        "BoardTip": ["칠판 (흰색/검정/끄기)", "ボード (白/黒/オフ)", "Board (white/black/off)"],
        "WhiteBoard": ["흰 칠판", "白ボード", "White"],
        "BlackBoard": ["검은 칠판", "黒ボード", "Black"],
        "Undo": ["되돌리기", "元に戻す", "Undo"],
        "Clear": ["지우기", "全消去", "Clear"],
        "ClearTip": ["전체 지우기", "すべて消去", "Clear all"],
        "Zoom": ["확대", "拡大", "Zoom"],
        "ZoomFactor": ["확대 배율", "拡大倍率", "Zoom level"],
        "Capture": ["캡처", "キャプチャ", "Capture"],
        "CaptureTip": ["화면과 필기를 PNG로 저장하고 클립보드에 복사", "画面と書き込みを PNG で保存してクリップボードにコピー", "Save the screen with ink as PNG and copy it to the clipboard"],
        "Saved": ["저장하고 클립보드에 복사했습니다\n%@\n(클릭하면 Finder에서 보기)", "保存してクリップボードにコピーしました\n%@\n(クリックで Finder に表示)", "Saved and copied to the clipboard\n%@\n(click to show in Finder)"],
        "CaptureFailed": ["캡처하지 못했습니다", "キャプチャできませんでした", "Capture failed"],
        "NeedPermission": ["화면 기록 권한이 필요합니다.\n시스템 설정 > 개인정보 보호 및 보안 > 화면 및 시스템 오디오 녹음에서 HighPen을 켠 뒤 HighPen을 종료하고 다시 실행하세요.\n(클릭하면 설정 열기)",
                           "画面収録の許可が必要です。\nシステム設定 > プライバシーとセキュリティ > 画面とシステムオーディオの録音 で HighPen をオンにしてから、HighPen を終了して再起動してください。\n(クリックで設定を開く)",
                           "Screen recording permission is needed.\nTurn on HighPen in System Settings > Privacy & Security > Screen & System Audio Recording, then quit and reopen HighPen.\n(click to open Settings)"],
        "HotkeyFail": ["다른 프로그램이 사용 중이라 등록하지 못한 단축키:", "他のアプリが使用中のため登録できなかったショートカット:", "Shortcuts in use by another app (not registered):"],
        "Hotkeys": ["단축키 설정", "ショートカット設定", "Shortcuts"],
        "HotkeyHint": ["바꿀 항목을 누른 뒤 새 조합을 누르세요.\nEsc 취소, Delete 단축키 없애기", "変更する項目を押してから新しい組み合わせを押してください。\nEsc で取り消し、Delete でショートカットなし", "Click an item, then press the new combination.\nEsc cancels, Delete removes the shortcut."],
        "PressKeys": ["키를 누르세요…", "キーを押してください…", "Press keys…"],
        "NoKey": ["없음", "なし", "None"],
        "HotkeyNeedMod": ["⌃, ⌥ 또는 ⌘와 함께 눌러야 합니다 (F1~F20은 단독 사용 가능)", "⌃、⌥ または ⌘ と一緒に押してください (F1~F20 は単独で使えます)", "Hold ⌃, ⌥ or ⌘ as well (F1–F20 can be used alone)"],
        "HotkeyDup": ["이미 '%@'에 쓰는 조합입니다", "すでに「%@」で使っている組み合わせです", "Already used for \"%@\""],
        "HotkeyWaitHint": ["눌러도 반응이 없으면 다른 프로그램이 이미 쓰는 조합입니다.", "押しても反応がない場合は、ほかのアプリがすでに使っている組み合わせです。", "If nothing happens, another app already uses that combination."],
        "HotkeyTaken": ["다른 프로그램이 사용 중인 조합입니다", "ほかのアプリが使用中の組み合わせです", "Another app is using this combination"],
        "ResetDefaults": ["기본값으로", "既定に戻す", "Reset all"],
        "About": ["정보", "情報", "About"],
        "AboutTip": ["저작자 및 라이선스 정보", "作者とライセンス情報", "Author and license"],
        "Tagline": ["비대면 강의용 macOS 펜 앱", "オンライン授業向け macOS ペンアプリ", "A macOS pen app for online lectures"],
        "Author": ["저작자", "作者", "Author"],
        "Email": ["이메일", "メール", "Email"],
        "License": ["라이선스", "ライセンス", "License"],
        "Close": ["닫기", "閉じる", "Close"],
        "Cycle": ["순환", "切替", "cycle"],
        "Settings": ["설정", "設定", "Settings"],
        "Collapse": ["접기/펴기", "折りたたみ/展開", "Collapse/expand"],
        "Quit": ["종료", "終了", "Quit"],
        "Monitor": ["작동 모니터", "使用モニター", "Monitor"],
        "PenColor": ["펜 색상", "ペンの色", "Pen color"],
        "PenSize": ["펜 두께", "ペンの太さ", "Pen width"],
        "Pressure": ["필압 반영", "筆圧", "Pressure"],
        "SpotColor": ["스팟 색상", "スポットの色", "Spot color"],
        "SpotSize": ["스팟 크기", "スポットの大きさ", "Spot size"],
        "Language": ["언어", "言語", "Language"],
        "Website": ["웹사이트", "Web サイト", "Website"],
        "Red": ["빨강", "赤", "Red"],
        "Orange": ["주황", "オレンジ", "Orange"],
        "Yellow": ["노랑", "黄", "Yellow"],
        "Green": ["초록", "緑", "Green"],
        "Blue": ["파랑", "青", "Blue"],
        "Purple": ["보라", "紫", "Purple"],
        "Black": ["검정", "黒", "Black"],
        "White": ["흰색", "白", "White"],
    ]

    static func t(_ key: String) -> String { text[key]?[cur] ?? key }

    // Saved code, else the system language, else English.
    static func index(_ code: String?) -> Int {
        let c = code ?? String((Locale.preferredLanguages.first ?? "en").prefix(2))
        return codes.firstIndex(of: c) ?? 2
    }
}

// ---------- settings (UserDefaults; missing or out-of-range values fall back to the default) ----------

func rgb(_ v: Int) -> NSColor {
    NSColor(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

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
    static var monitor: Int { get { int("Monitor", 0, 0...63) } set { d.set(newValue, forKey: "Monitor") } }
    // toolbar offset from the top-left of the monitor's visible area, in points
    static var barX: Double { get { num("BarX", 20, 0...100_000) } set { d.set(newValue, forKey: "BarX") } }
    static var barY: Double { get { num("BarY", 20, 0...100_000) } set { d.set(newValue, forKey: "BarY") } }
    static var language: String? { get { d.string(forKey: "Language") } set { d.set(newValue, forKey: "Language") } }
    // Shortcuts changed from their defaults, by action id (Hotkey.saved, or "" = no shortcut).
    static var hotkeys: [String: String] { get { d.dictionary(forKey: "Hotkeys") as? [String: String] ?? [:] } set { d.set(newValue, forKey: "Hotkeys") } }
}

func screen(_ i: Int) -> NSScreen {
    let all = NSScreen.screens
    return i < all.count ? all[i] : all[0]
}

func displayID(_ s: NSScreen) -> CGDirectDisplayID {
    (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
}

// ---------- windows ----------

let baseLevel = Int(CGWindowLevelForKey(.popUpMenuWindow))

// Borderless panel that never activates the app and shows on every Space, including over full-screen apps.
// Level offsets: 0 zoom, 1 ink overlay, 2 spot, 3 toolbar / settings, 4 toast.
final class Panel: NSPanel {
    var keyable = false
    override var canBecomeKey: Bool { keyable }

    init(level: Int, clickThrough: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 10, height: 10), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        self.level = NSWindow.Level(rawValue: baseLevel + level)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = clickThrough
        appearance = NSAppearance(named: .darkAqua)
    }
}

// Target/action with a closure, kept alive by the control itself.
final class Act: NSObject {
    let f: (NSControl) -> Void
    init(_ f: @escaping (NSControl) -> Void) { self.f = f }
    @objc func run(_ c: NSControl) { f(c) }
}
var actKey: UInt8 = 0
extension NSControl {
    func on(_ f: @escaping (NSControl) -> Void) {
        let a = Act(f)
        objc_setAssociatedObject(self, &actKey, a, .OBJC_ASSOCIATION_RETAIN)
        target = a
        action = #selector(Act.run(_:))
    }
}

// A view that is clicked as a whole (labels inside do not swallow the click).
final class ClickView: NSView {
    var click: () -> Void = {}
    override func hitTest(_ p: NSPoint) -> NSView? { frame.contains(p) ? self : nil }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func mouseUp(with e: NSEvent) { click() }
}

// Hover tracking that also works while HighPen is not the active app (system tooltips only show in the active app).
final class Hover: NSObject {
    let enter: () -> Void, exit: () -> Void
    init(_ enter: @escaping () -> Void, _ exit: @escaping () -> Void) { self.enter = enter; self.exit = exit }
    @objc(mouseEntered:) func mouseEntered(with e: NSEvent) { enter() }
    @objc(mouseExited:) func mouseExited(with e: NSEvent) { exit() }
}
var hoverKey: UInt8 = 0
extension NSView {
    func onHover(_ enter: @escaping () -> Void, _ exit: @escaping () -> Void) {
        let h = Hover(enter, exit) // tracking areas do not retain their owner
        objc_setAssociatedObject(self, &hoverKey, h, .OBJC_ASSOCIATION_RETAIN)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: h, userInfo: nil))
    }
}

// Tool cursors: an outlined SF Symbol with the hot spot at its tip (bottom-left), or a ring centred on the eraser's reach.
func symbolCursor(_ symbol: String) -> NSCursor {
    let n: CGFloat = 28
    let img = NSImage(size: NSSize(width: n, height: n), flipped: false) { _ in
        let cfg = NSImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        guard let black = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg.applying(.init(paletteColors: [.black]))),
              let white = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(cfg.applying(.init(paletteColors: [.white]))) else { return false }
        let r = NSRect(origin: NSPoint(x: 2, y: 2), size: black.size)
        for dx in [-1.5, 0, 1.5] { for dy in [-1.5, 0, 1.5] { black.draw(in: r.offsetBy(dx: dx, dy: dy)) } }
        white.draw(in: r)
        return true
    }
    return NSCursor(image: img, hotSpot: NSPoint(x: 3, y: n - 3))
}

func ringCursor(_ d: CGFloat) -> NSCursor {
    let n = d + 4
    let img = NSImage(size: NSSize(width: n, height: n), flipped: false) { r in
        let o = NSBezierPath(ovalIn: r.insetBy(dx: 2, dy: 2))
        o.lineWidth = 3; NSColor.black.setStroke(); o.stroke()
        o.lineWidth = 1.5; NSColor.white.setStroke(); o.stroke()
        return true
    }
    return NSCursor(image: img, hotSpot: NSPoint(x: n / 2, y: n / 2))
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

final class SpotView: NSView {
    var color = NSColor.yellow
    override func draw(_ r: NSRect) {
        color.withAlphaComponent(0.4).setFill()
        NSBezierPath(ovalIn: bounds).fill()
    }
}

// ---------- ink ----------

func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }

func segDist(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = b.x - a.x, dy = b.y - a.y
    let len = dx * dx + dy * dy
    let t = len == 0 ? 0 : max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len))
    return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
}

final class Stroke {
    var pts: [CGPoint] = []
    var prs: [CGFloat] = [] // 0...1, 0.5 = nominal width
    let color: NSColor, width: CGFloat, highlighter: Bool, pressure: Bool

    init(color: NSColor, width: CGFloat, highlighter: Bool, pressure: Bool) {
        self.color = color; self.width = width; self.highlighter = highlighter; self.pressure = pressure
    }

    func add(_ p: CGPoint, _ pr: CGFloat) {
        if let l = pts.last, hypot(l.x - p.x, l.y - p.y) < 0.5 { return }
        pts.append(p); prs.append(pr)
    }

    func w(_ i: Int) -> CGFloat { pressure ? width * (0.2 + 1.6 * prs[i]) : width }

    // Smoothed through the midpoints of consecutive points; one point gives a dot (round cap).
    func path() -> CGPath {
        let p = CGMutablePath()
        p.move(to: pts[0])
        if pts.count < 3 { p.addLine(to: pts[pts.count - 1]); return p }
        for i in 1..<pts.count - 1 { p.addQuadCurve(to: mid(pts[i], pts[i + 1]), control: pts[i]) }
        p.addLine(to: pts[pts.count - 1])
        return p
    }

    func draw(_ ctx: CGContext) {
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(highlighter ? color.withAlphaComponent(0.5).cgColor : color.cgColor)
        if !pressure || pts.count < 3 {
            ctx.setLineWidth(w(0))
            ctx.addPath(path())
            ctx.strokePath()
            return
        }
        // variable width: one curve piece per point, each with its own width
        var from = pts[0]
        for i in 1..<pts.count - 1 {
            let to = mid(pts[i], pts[i + 1])
            ctx.setLineWidth(w(i))
            ctx.move(to: from)
            ctx.addQuadCurve(to: to, control: pts[i])
            ctx.strokePath()
            from = to
        }
        ctx.setLineWidth(w(pts.count - 1))
        ctx.move(to: from)
        ctx.addLine(to: pts[pts.count - 1])
        ctx.strokePath()
    }

    func hits(_ p: CGPoint, _ r: CGFloat) -> Bool {
        let lim = r + (pressure ? width * 1.8 : width) / 2
        if pts.count == 1 { return hypot(p.x - pts[0].x, p.y - pts[0].y) <= lim }
        for i in 1..<pts.count where segDist(p, pts[i - 1], pts[i]) <= lim { return true }
        return false
    }
}

enum Tool { case pen, highlighter, eraser }

// One undo step: a pen stroke, or every stroke removed by one eraser drag.
struct Edit {
    var added: [Stroke] = []
    var removed: [Stroke] = []
}

// Ink for three pages: 0 = screen annotations, 1 = white board, 2 = black board.
final class InkView: NSView {
    var pages: [[Stroke]] = [[], [], []]
    var history: [[Edit]] = [[], [], []]
    var page = 0 { didSet { needsDisplay = true } }
    var tool = Tool.pen
    var newStroke: () -> Stroke = { Stroke(color: .red, width: 4, highlighter: false, pressure: false) }
    // Ink lives in coordinates of the unzoomed screen. While zoomed, content point c is shown at (c - zoomOrigin) * zoomScale.
    var zoomScale: CGFloat = 1, zoomOrigin = CGPoint.zero
    var cursor = NSCursor.arrow
    private var current: Stroke?
    private var erased: [Stroke] = []

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        if trackingAreas.isEmpty {
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
        }
    }
    // Tracking events keep coming while the window ignores the mouse (outside pen mode),
    // so only show the tool cursor while the overlay actually takes input.
    private func showCursor() { if window?.ignoresMouseEvents == false { cursor.set() } }
    override func mouseEntered(with e: NSEvent) { showCursor() }
    override func mouseMoved(with e: NSEvent) { showCursor() }
    override func cursorUpdate(with e: NSEvent) { showCursor() }

    func content(_ v: CGPoint) -> CGPoint {
        CGPoint(x: v.x / zoomScale + zoomOrigin.x, y: v.y / zoomScale + zoomOrigin.y)
    }

    private func point(_ e: NSEvent) -> CGPoint { content(convert(e.locationInWindow, from: nil)) }
    private func pressure(_ e: NSEvent) -> CGFloat { e.subtype == .tabletPoint ? CGFloat(e.pressure) : 0.5 }

    override func mouseDown(with e: NSEvent) {
        cursor.set()
        if tool == .eraser { erased = []; erase(at: point(e)); return }
        let s = newStroke()
        s.add(point(e), pressure(e))
        current = s
        pages[page].append(s)
        dirty(s)
    }

    override func mouseDragged(with e: NSEvent) {
        if tool == .eraser { erase(at: point(e)); return }
        guard let s = current else { return }
        s.add(point(e), pressure(e))
        dirty(s)
    }

    override func mouseUp(with e: NSEvent) {
        if tool == .eraser { endErase(); return }
        if let s = current { history[page].append(Edit(added: [s])) }
        current = nil
    }

    // Redraw only around the newest points of a stroke being drawn.
    private func dirty(_ s: Stroke) {
        let tail = s.pts.suffix(3)
        var r = CGRect(origin: tail.first!, size: .zero)
        for p in tail { r = r.union(CGRect(origin: p, size: .zero)) }
        let pad = s.width * 2 + 2
        r = r.insetBy(dx: -pad, dy: -pad)
        setNeedsDisplay(NSRect(x: (r.minX - zoomOrigin.x) * zoomScale, y: (r.minY - zoomOrigin.y) * zoomScale,
                               width: r.width * zoomScale, height: r.height * zoomScale))
    }

    func erase(at p: CGPoint) {
        let hit = pages[page].filter { $0.hits(p, 6 / zoomScale) }
        if hit.isEmpty { return }
        pages[page].removeAll { s in hit.contains { $0 === s } }
        erased += hit
        needsDisplay = true
    }

    func endErase() {
        if !erased.isEmpty { history[page].append(Edit(removed: erased)) }
        erased = []
    }

    func undo() {
        guard let e = history[page].popLast() else { return }
        pages[page].removeAll { s in e.added.contains { $0 === s } }
        pages[page] += e.removed
        needsDisplay = true
    }

    func clear() {
        pages[page] = []
        history[page] = []
        needsDisplay = true
    }

    override func draw(_ r: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.scaleBy(x: zoomScale, y: zoomScale)
        ctx.translateBy(x: -zoomOrigin.x, y: -zoomOrigin.y)
        // highlighter beneath the pen
        for s in pages[page] where s.highlighter { s.draw(ctx) }
        for s in pages[page] where !s.highlighter { s.draw(ctx) }
    }
}

// ---------- zoom ----------

// Live zoom of one monitor: ScreenCaptureKit streams the screen (without HighPen's own windows) and a
// click-through window shows part of it enlarged. The view is positioned so the content under the pointer
// stays under the pointer, so clicks land exactly where they appear.
@MainActor
final class Zoomer: NSObject, SCStreamOutput {
    let window = Panel(level: 0, clickThrough: true)
    let view = NSView()
    private var stream: SCStream?
    private var timer: Timer?
    private var frame = NSRect.zero
    private(set) var factor: CGFloat = 2
    // While frozen the view stays put so the user can draw on it.
    var frozen = false
    // Bottom-left of the area being shown, in screen-local points (nil = zoom off).
    private(set) var origin: CGPoint?
    var onChange: () -> Void = {}
    var active: Bool { stream != nil }

    override init() {
        super.init()
        view.wantsLayer = true
        view.layer?.contentsGravity = .resize
        window.contentView = view
    }

    func start(_ screen: NSScreen, factor: CGFloat) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard !active, let display = content.displays.first(where: { $0.displayID == displayID(screen) }) else { return }
        let me = content.applications.filter { $0.processID == getpid() }
        let filter = SCContentFilter(display: display, excludingApplications: me, exceptingWindows: [])
        let conf = SCStreamConfiguration()
        conf.width = Int(screen.frame.width * screen.backingScaleFactor)
        conf.height = Int(screen.frame.height * screen.backingScaleFactor)
        conf.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        conf.showsCursor = false
        conf.queueDepth = 4
        let s = SCStream(filter: filter, configuration: conf, delegate: nil)
        try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
        try await s.startCapture()
        stream = s
        frame = screen.frame
        self.factor = factor
        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
        update(force: true)
        let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.update(force: false) }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        guard let s = stream else { return }
        stream = nil
        timer?.invalidate()
        timer = nil
        s.stopCapture { _ in }
        window.orderOut(nil)
        view.layer?.contents = nil
        origin = nil
        onChange()
    }

    // Can be changed while zoomed; the view updates on the spot.
    func setFactor(_ f: CGFloat) {
        factor = f
        update(force: true)
    }

    func update(force: Bool) {
        guard active, force || !frozen else { return }
        var p = NSEvent.mouseLocation
        p.x = min(max(p.x, frame.minX), frame.maxX - 1)
        p.y = min(max(p.y, frame.minY), frame.maxY - 1)
        let k = 1 - 1 / factor
        let o = CGPoint(x: ((p.x - frame.minX) * k).rounded(), y: ((p.y - frame.minY) * k).rounded())
        if o == origin && !force { return }
        origin = o
        let u = 1 / factor
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.layer?.contentsRect = CGRect(x: o.x / frame.width, y: o.y / frame.height, width: u, height: u)
        CATransaction.commit()
        onChange()
    }

    nonisolated func stream(_ s: SCStream, didOutputSampleBuffer sb: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let pb = CMSampleBufferGetImageBuffer(sb),
              let surface = CVPixelBufferGetIOSurface(pb)?.takeUnretainedValue() else { return }
        MainActor.assumeIsolated {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            view.layer?.contents = surface
            CATransaction.commit()
        }
    }
}

// ---------- global hotkeys (Carbon; Ctrl+Option+key) ----------

var hotkeyRun: [UInt32: () -> Void] = [:]

func installHotkeyHandler() {
    var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
        var id = EventHotKeyID()
        GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                          MemoryLayout<EventHotKeyID>.size, nil, &id)
        hotkeyRun[id.id]?()
        return noErr
    }, 1, &spec, nil, nil)
}

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

// ---------- app ----------

let panelBg = rgb(0x2B2E33), activeBg = rgb(0x3E6FB0), idleBg = rgb(0x3A3D42), lineColor = rgb(0x141517)

func label(_ s: String, size: CGFloat = 12, color: NSColor = .white) -> NSTextField {
    let l = NSTextField(labelWithString: s)
    l.font = .systemFont(ofSize: size)
    l.textColor = color
    return l
}

func fixedSize(_ v: NSView, _ w: CGFloat?, _ h: CGFloat?) {
    v.translatesAutoresizingMaskIntoConstraints = false
    if let w = w { v.widthAnchor.constraint(equalToConstant: w).isActive = true }
    if let h = h { v.heightAnchor.constraint(equalToConstant: h).isActive = true }
}

@MainActor
final class Controller: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let overlay = Panel(level: 1, clickThrough: true)
    let ink = InkView()
    let spot = Panel(level: 2, clickThrough: true)
    let spotView = SpotView()
    let bar = Panel(level: 3, clickThrough: false)
    let settings = Panel(level: 3, clickThrough: false)
    var toast: Panel?
    let hintWin = Panel(level: 4, clickThrough: true)
    let hintLabel = NSTextField(wrappingLabelWithString: "")
    weak var hintOwner: NSView?
    let penCursor = symbolCursor("pencil"), highlightCursor = symbolCursor("highlighter"), eraserCursor = ringCursor(16)
    let zoomer = Zoomer()
    var spotTimer: Timer?

    var penMode = false, tool = Tool.pen, board = 0, settingsOpen = false, collapsed = false
    var buttons: [String: NSButton] = [:]
    var buttonColumn = NSStackView()
    var collapseBtn = NSButton()
    var penSwatches: NSSegmentedControl?, highlightSwatches: NSSegmentedControl?
    var failedHotkeys: [String] = []
    var placing = false
    var lastOtherApp: NSRunningApplication? // the app to hand focus back to
    var holdingFocus = false
    var hotkeyRefs: [EventHotKeyRef] = []
    var hotkeyWin: Panel?, aboutWin: Panel?
    var waiting: Int? // index of the action whose new shortcut is being typed
    var keyBoxes: [NSButton] = []
    let editorStatus = NSTextField(wrappingLabelWithString: "")

    // Every action that can have a shortcut, in the order the shortcut editor lists them.
    lazy var actions: [HotkeyAction] = {
        let ctrlOpt = controlKey | optionKey
        var a: [HotkeyAction] = [
            HotkeyAction(id: "Spot", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_S, name: "S"), title: { Lang.t("MouseSpot") }, run: { [unowned self] in self.toggleSpot() }),
            HotkeyAction(id: "Pen", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_P, name: "P"), title: { Lang.t("Pen") }, run: { [unowned self] in self.togglePen() }),
            HotkeyAction(id: "Highlighter", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_L, name: "L"), title: { Lang.t("Highlighter") }, run: { [unowned self] in self.toggleHighlighter() }),
            HotkeyAction(id: "Eraser", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_E, name: "E"), title: { Lang.t("Eraser") }, run: { [unowned self] in self.eraserHotkey() }),
            HotkeyAction(id: "Board", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_B, name: "B"), title: { Lang.t("Board") }, run: { [unowned self] in self.cycleBoard() }),
            HotkeyAction(id: "Undo", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Z, name: "Z"), title: { Lang.t("Undo") }, run: { [unowned self] in self.ink.undo() }),
            HotkeyAction(id: "Clear", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_C, name: "C"), title: { Lang.t("ClearTip") }, run: { [unowned self] in self.ink.clear() }),
            HotkeyAction(id: "Zoom", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_X, name: "X"), title: { Lang.t("Zoom") }, run: { [unowned self] in self.toggleZoom() }),
            HotkeyAction(id: "Capture", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_F, name: "F"), title: { Lang.t("Capture") }, run: { [unowned self] in self.capture() }),
            HotkeyAction(id: "Settings", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_D, name: "D"), title: { Lang.t("Settings") }, run: { [unowned self] in self.toggleSettings() }),
            HotkeyAction(id: "Collapse", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_H, name: "H"), title: { Lang.t("Collapse") }, run: { [unowned self] in self.toggleCollapse() }),
            HotkeyAction(id: "Monitor", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_M, name: "M"), title: { Lang.t("Monitor") + " (" + Lang.t("Cycle") + ")" }, run: { [unowned self] in self.cycleMonitor() }),
            HotkeyAction(id: "Pressure", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_R, name: "R"), title: { Lang.t("Pressure") }, run: { [unowned self] in self.togglePressure() }),
            HotkeyAction(id: "Quit", def: Hotkey(mods: ctrlOpt, key: kVK_ANSI_Q, name: "Q"), title: { Lang.t("Quit") }, run: { NSApp.terminate(nil) }),
        ]
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8]
        for i in 0..<Cfg.palette.count {
            a.append(HotkeyAction(id: "Color" + String(i), def: Hotkey(mods: ctrlOpt, key: digits[i], name: String(i + 1)),
                                  title: { Lang.t("PenColor") + ": " + Lang.t(Cfg.colorNames[i]) },
                                  run: { [unowned self] in self.setPenColor(i) }))
        }
        return a
    }()

    func applicationDidFinishLaunching(_ n: Notification) {
        Lang.cur = Lang.index(Cfg.language)
        setupMenu()
        setupHint()

        overlay.contentView = ink
        spot.contentView = spotView
        bar.isMovableByWindowBackground = true
        bar.delegate = self
        ink.newStroke = { [unowned self] in
            self.tool == .highlighter
                ? Stroke(color: Cfg.palette[Cfg.highlightColor], width: Cfg.highlightSize, highlighter: true, pressure: false)
                : Stroke(color: Cfg.palette[Cfg.penColor], width: Cfg.penSize, highlighter: false, pressure: Cfg.pressure)
        }
        zoomer.onChange = { [unowned self] in self.applyZoomTransform() }

        installHotkeyHandler()
        registerHotkeys()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] e in
            MainActor.assumeIsolated { self.handleKey(e) } ? nil : e
        }

        rebuild()
        placeWindows()
        overlay.orderFrontRegardless()
        bar.orderFrontRegardless()

        lastOtherApp = NSWorkspace.shared.frontmostApplication.flatMap { $0 == .current ? nil : $0 }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [unowned self] n in
            let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { if let a = app, a != .current { self.lastOtherApp = a } }
        }
        // keep up with monitors being plugged in or removed (and resolution changes) while running
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [unowned self] _ in
            MainActor.assumeIsolated {
                self.zoomer.stop() // the zoomed monitor may be gone
                self.rebuild()
                self.placeWindows()
            }
        }
        if !failedHotkeys.isEmpty { showToast(Lang.t("HotkeyFail") + "\n" + failedHotkeys.joined(separator: ", "), seconds: 8) }
    }

    // Launching again or clicking the Dock icon brings the toolbar back.
    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if collapsed { toggleCollapse() }
        bar.orderFrontRegardless()
        return false
    }

    func applicationWillTerminate(_ n: Notification) { zoomer.stop() }

    func setupMenu() {
        let menu = NSMenu()
        let item = NSMenuItem()
        menu.addItem(item)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: Lang.t("Quit") + " HighPen", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = appMenu
        NSApp.mainMenu = menu
    }

    // The action's current shortcut (nil = none).
    func hotkey(_ id: String) -> Hotkey? {
        let def = actions.first { $0.id == id }?.def
        guard let s = Cfg.hotkeys[id] else { return def }
        return s.isEmpty ? nil : Hotkey(saved: s) ?? def
    }

    func unregisterHotkeys() {
        for r in hotkeyRefs { UnregisterEventHotKey(r) }
        hotkeyRefs = []
        hotkeyRun = [:]
    }

    func registerHotkeys() {
        unregisterHotkeys()
        failedHotkeys = []
        for (n, a) in actions.enumerated() {
            guard let h = hotkey(a.id) else { continue }
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: OSType(0x4850_454E), id: UInt32(n + 1)) // 'HPEN'
            if RegisterEventHotKey(UInt32(h.key), UInt32(h.mods), id, GetApplicationEventTarget(), 0, &ref) == noErr, let r = ref {
                hotkeyRefs.append(r)
                hotkeyRun[id.id] = a.run
            } else {
                failedHotkeys.append(h.text)
            }
        }
    }

    // Whether another app already owns the combination (registered briefly under a spare id).
    func available(_ h: Hotkey) -> Bool {
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: OSType(0x4850_454E), id: 0xBFFF)
        guard RegisterEventHotKey(UInt32(h.key), UInt32(h.mods), id, GetApplicationEventTarget(), 0, &ref) == noErr, let r = ref else { return false }
        UnregisterEventHotKey(r)
        return true
    }

    func combo(_ id: String) -> String { hotkey(id)?.text ?? "" }
    func tip(_ text: String, _ id: String) -> String {
        let c = combo(id)
        return c.isEmpty ? text : text + "   " + c
    }

    // ---------- hover hint (name + shortcut beside the control) ----------

    func setupHint() {
        let box = NSView()
        box.wantsLayer = true
        box.layer?.backgroundColor = panelBg.cgColor
        box.layer?.borderColor = activeBg.cgColor
        box.layer?.borderWidth = 1
        box.layer?.cornerRadius = 4
        hintLabel.textColor = .white
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.preferredMaxLayoutWidth = 320
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 8),
            hintLabel.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -8),
            hintLabel.topAnchor.constraint(equalTo: box.topAnchor, constant: 5),
            hintLabel.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -5),
        ])
        hintWin.contentView = box
    }

    func hint(_ v: NSView, _ text: String) {
        v.onHover({ [unowned self, unowned v] in self.showHint(text, for: v) },
                  { [unowned self, unowned v] in if self.hintOwner === v { self.hintWin.orderOut(nil) } }) // exits can arrive after the next enter
    }

    // Beside the control: to the right, or to the left when that would cover the settings panel or leave the monitor.
    func showHint(_ text: String, for v: NSView) {
        guard let w = v.window else { return }
        hintOwner = v
        hintLabel.stringValue = text
        let s = hintWin.contentView!.fittingSize
        let r = w.convertToScreen(v.convert(v.bounds, to: nil))
        let vf = screen(Cfg.monitor).visibleFrame
        var f = NSRect(x: w.frame.maxX + 6, y: r.midY - s.height / 2, width: s.width, height: s.height)
        if f.maxX > vf.maxX || (w === bar && settings.isVisible && settings.frame.intersects(f)) {
            f.origin.x = w.frame.minX - 6 - s.width
        }
        f.origin.y = min(max(f.minY, vf.minY), vf.maxY - s.height)
        hintWin.setFrame(f, display: true)
        hintWin.orderFrontRegardless()
    }

    // ---------- layout ----------

    func placeWindows() {
        if Cfg.monitor >= NSScreen.screens.count { Cfg.monitor = 0 }
        overlay.setFrame(screen(Cfg.monitor).frame, display: true)
        placeBar()
    }

    func placeBar() {
        guard let v = bar.contentView else { return }
        let vf = screen(Cfg.monitor).visibleFrame
        let s = v.fittingSize
        let x = min(max(vf.minX + Cfg.barX, vf.minX), vf.maxX - s.width)
        let y = min(max(vf.maxY - Cfg.barY - s.height, vf.minY), vf.maxY - s.height)
        placing = true
        bar.setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
        placing = false
        placeSettings()
    }

    // The settings panel opens to the right of the bar, or to its left when it would run past the monitor edge.
    func placeSettings() {
        guard settingsOpen && !collapsed, let v = settings.contentView else { settings.orderOut(nil); return }
        let vf = screen(Cfg.monitor).visibleFrame
        let s = v.fittingSize
        let x = bar.frame.maxX + s.width <= vf.maxX ? bar.frame.maxX : bar.frame.minX - s.width
        let y = max(bar.frame.maxY - s.height, vf.minY)
        settings.setFrame(NSRect(x: x, y: y, width: s.width, height: s.height), display: true)
        settings.orderFrontRegardless()
    }

    func windowDidMove(_ n: Notification) {
        guard !placing, (n.object as? NSWindow) === bar else { return }
        let vf = screen(Cfg.monitor).visibleFrame
        Cfg.barX = bar.frame.minX - vf.minX
        Cfg.barY = vf.maxY - bar.frame.maxY
        placeSettings()
    }

    // ---------- UI building ----------

    func rebuild() {
        hintWin.orderOut(nil) // its control is about to go away
        bar.contentView = buildBar()
        settings.contentView = buildSettings()
        applySpot()
        applyMode()
    }

    func makeButton(_ id: String, _ symbol: String, _ title: String, _ tooltip: String, _ run: @escaping () -> Void) -> NSButton {
        let img = NSImage(systemSymbolName: symbol, accessibilityDescription: title)?
            .withSymbolConfiguration(.init(pointSize: 18, weight: .regular)) ?? NSImage()
        let b = NSButton(title: title, image: img, target: nil, action: nil)
        b.on { _ in run() }
        b.isBordered = false
        b.imagePosition = .imageAbove
        b.contentTintColor = .white
        b.attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 10)])
        b.wantsLayer = true
        b.layer?.backgroundColor = idleBg.cgColor
        hint(b, tooltip)
        fixedSize(b, 84, 52)
        buttons[id] = b
        return b
    }

    func buildBar() -> NSView {
        buttons = [:]
        // header: drag area (the whole panel is draggable by its background) + collapse arrow
        let header = NSView()
        header.wantsLayer = true
        header.layer?.backgroundColor = rgb(0x4A522A).cgColor
        fixedSize(header, 84, 30)
        let name = label("HighPen", size: 11)
        name.font = .systemFont(ofSize: 11, weight: .semibold)
        name.frame = NSRect(x: 6, y: 7, width: 54, height: 16)
        header.addSubview(name)
        collapseBtn = NSButton(image: NSImage(), target: nil, action: nil)
        collapseBtn.on { [unowned self] _ in self.toggleCollapse() }
        collapseBtn.isBordered = false
        collapseBtn.contentTintColor = .white
        collapseBtn.wantsLayer = true
        collapseBtn.layer?.backgroundColor = idleBg.cgColor
        hint(collapseBtn, tip(Lang.t("Collapse"), "Collapse"))
        collapseBtn.frame = NSRect(x: 56, y: 0, width: 28, height: 30)
        header.addSubview(collapseBtn)

        let col = NSStackView()
        col.orientation = .vertical
        col.spacing = 1
        col.addArrangedSubview(makeButton("Spot", "smallcircle.filled.circle", Lang.t("Spot"), tip(Lang.t("MouseSpot"), "Spot")) { [unowned self] in self.toggleSpot() })
        col.addArrangedSubview(makeButton("Pen", "pencil.tip", Lang.t("Pen"), tip(Lang.t("Pen"), "Pen")) { [unowned self] in self.togglePen() })
        col.addArrangedSubview(makeButton("Highlighter", "highlighter", Lang.t("Highlighter"), tip(Lang.t("Highlighter"), "Highlighter")) { [unowned self] in self.toggleHighlighter() })
        col.addArrangedSubview(makeButton("Eraser", "eraser", Lang.t("Eraser"), tip(Lang.t("Eraser"), "Eraser") + "\n" + Lang.t("EraserTip")) { [unowned self] in self.toggleEraser() })
        col.addArrangedSubview(makeButton("Board", "rectangle.inset.filled", Lang.t("Board"), tip(Lang.t("BoardTip"), "Board")) { [unowned self] in self.cycleBoard() })
        col.addArrangedSubview(makeButton("Undo", "arrow.uturn.backward", Lang.t("Undo"), tip(Lang.t("Undo"), "Undo")) { [unowned self] in self.ink.undo() })
        col.addArrangedSubview(makeButton("Clear", "trash", Lang.t("Clear"), tip(Lang.t("ClearTip"), "Clear")) { [unowned self] in self.ink.clear() })
        col.addArrangedSubview(makeButton("Zoom", "plus.magnifyingglass", Lang.t("Zoom"), tip(Lang.t("Zoom"), "Zoom")) { [unowned self] in self.toggleZoom() })
        col.addArrangedSubview(makeButton("Capture", "camera", Lang.t("Capture"), tip(Lang.t("CaptureTip"), "Capture")) { [unowned self] in self.capture() })
        col.addArrangedSubview(makeButton("Settings", "gearshape", Lang.t("Settings"), tip(Lang.t("Settings"), "Settings")) { [unowned self] in self.toggleSettings() })
        col.addArrangedSubview(makeButton("About", "info.circle", Lang.t("About"), Lang.t("AboutTip")) { [unowned self] in self.toggleAbout() })
        let quit = makeButton("Quit", "xmark.circle.fill", Lang.t("Quit"), tip(Lang.t("Quit"), "Quit")) { NSApp.terminate(nil) }
        quit.contentTintColor = rgb(0xFF453A)
        col.addArrangedSubview(quit)
        buttonColumn = col

        let root = NSStackView(views: [header, col])
        root.orientation = .vertical
        root.spacing = 1
        root.edgeInsets = NSEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        root.wantsLayer = true
        root.layer?.backgroundColor = lineColor.cgColor
        return root
    }

    func swatches(_ sel: Int, _ pick: @escaping (Int) -> Void) -> NSSegmentedControl {
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

    func slider(_ min: Double, _ max: Double, _ v: Double, _ f: @escaping (Double) -> Void) -> NSSlider {
        let s = NSSlider(value: v, minValue: min, maxValue: max, target: nil, action: nil)
        s.on { c in f((c as! NSSlider).doubleValue) }
        fixedSize(s, 190, nil)
        return s
    }

    func segments(_ labels: [String], _ sel: Int, _ f: @escaping (Int) -> Void) -> NSSegmentedControl {
        let s = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: nil)
        s.selectedSegment = sel
        s.on { c in f((c as! NSSegmentedControl).selectedSegment) }
        return s
    }

    func buildSettings() -> NSView {
        let col = NSStackView()
        col.orientation = .vertical
        col.alignment = .leading
        col.spacing = 6
        col.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        col.wantsLayer = true
        col.layer?.backgroundColor = panelBg.cgColor
        col.layer?.borderColor = lineColor.cgColor
        col.layer?.borderWidth = 1
        func title(_ k: String) { col.addArrangedSubview(label(Lang.t(k))) }
        func sep() {
            let b = NSBox()
            b.boxType = .separator
            fixedSize(b, 190, nil)
            col.addArrangedSubview(b)
        }

        title("Monitor")
        let mon = segments((1...NSScreen.screens.count).map { String($0) }, Cfg.monitor) { [unowned self] i in self.setMonitor(i) }
        hint(mon, tip(Lang.t("Monitor") + " (" + Lang.t("Cycle") + ")", "Monitor"))
        col.addArrangedSubview(mon)
        sep()

        title("PenColor")
        let ps = swatches(Cfg.penColor) { Cfg.penColor = $0 }
        hint(ps, (0..<Cfg.palette.count).map { tip(Lang.t(Cfg.colorNames[$0]), "Color" + String($0)) }.joined(separator: "\n"))
        penSwatches = ps
        col.addArrangedSubview(ps)
        title("PenSize")
        col.addArrangedSubview(slider(1, 30, Cfg.penSize) { Cfg.penSize = $0 })
        let pr = NSButton(checkboxWithTitle: Lang.t("Pressure"), target: nil, action: nil)
        pr.state = Cfg.pressure ? .on : .off
        hint(pr, tip(Lang.t("Pressure"), "Pressure"))
        pr.on { c in Cfg.pressure = (c as! NSButton).state == .on }
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
        col.addArrangedSubview(swatches(Cfg.spotColor) { [unowned self] in Cfg.spotColor = $0; self.applySpot() })
        title("SpotSize")
        col.addArrangedSubview(slider(20, 200, Cfg.spotSize) { [unowned self] in Cfg.spotSize = $0; self.applySpot() })
        sep()

        title("ZoomFactor")
        col.addArrangedSubview(segments(Cfg.zoomFactors.map { String(format: "%gx", $0) }, Cfg.zoomIndex) { [unowned self] i in
            Cfg.zoomIndex = i
            self.zoomer.setFactor(Cfg.zoomFactors[i])
        })
        sep()

        title("Language")
        col.addArrangedSubview(segments(Lang.names, Lang.cur) { [unowned self] i in self.setLanguage(i) })
        sep()

        let keys = NSButton(title: Lang.t("Hotkeys"), target: nil, action: nil)
        keys.on { [unowned self] _ in self.showHotkeyEditor() }
        col.addArrangedSubview(keys)
        if !failedHotkeys.isEmpty {
            let w = NSTextField(wrappingLabelWithString: Lang.t("HotkeyFail") + "\n" + failedHotkeys.joined(separator: ", "))
            w.textColor = rgb(0xFF9F0A)
            w.font = .systemFont(ofSize: 11)
            fixedSize(w, 190, nil)
            col.addArrangedSubview(w)
        }
        sep()

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
        col.addArrangedSubview(label("HighPen v" + version, size: 11, color: .gray))
        return col
    }

    // ---------- behaviour ----------

    func toggleSpot() { Cfg.spotOn.toggle(); applySpot() }
    func togglePen() { if penMode && tool == .pen { setPen(false) } else { tool = .pen; setPen(true) } }
    func toggleHighlighter() { if penMode && tool == .highlighter { setPen(false) } else { tool = .highlighter; setPen(true) } }
    func toggleEraser() {
        if penMode && tool == .eraser { tool = .pen } else { tool = .eraser; penMode = true }
        applyMode()
    }
    // First press enters eraser mode; pressing again while erasing wipes the page.
    func eraserHotkey() { if penMode && tool == .eraser { ink.clear() } else { toggleEraser() } }
    func toggleSettings() { settingsOpen.toggle(); applyMode() }
    func toggleCollapse() { collapsed.toggle(); hintWin.orderOut(nil); applyMode() }
    func togglePressure() { Cfg.pressure.toggle(); settings.contentView = buildSettings(); placeSettings() }

    func setPen(_ on: Bool) {
        penMode = on
        if !on { tool = .pen; board = 0 }
        applyMode()
    }

    func cycleBoard() {
        board = (board + 1) % 3
        if board != 0 { penMode = true; if tool == .eraser { tool = .pen } }
        // keep the pen visible against the board colour
        if board == 2 && Cfg.penColor == Cfg.black { Cfg.penColor = Cfg.white }
        else if board == 1 && Cfg.penColor == Cfg.white { Cfg.penColor = Cfg.black }
        penSwatches?.selectedSegment = Cfg.penColor
        applyMode()
    }

    // Colour shortcuts change the tool in use: the highlighter while it is on, otherwise the pen.
    func setPenColor(_ i: Int) {
        if tool == .highlighter { Cfg.highlightColor = i; highlightSwatches?.selectedSegment = i }
        else { Cfg.penColor = i; penSwatches?.selectedSegment = i }
    }

    func cycleMonitor() { setMonitor((Cfg.monitor + 1) % NSScreen.screens.count) }

    func setMonitor(_ i: Int) {
        guard i != Cfg.monitor else { return }
        zoomer.stop() // zoom belongs to the previous monitor
        Cfg.monitor = i
        rebuild()
        placeWindows()
    }

    func setLanguage(_ i: Int) {
        guard i != Lang.cur else { return }
        Lang.cur = i
        Cfg.language = Lang.codes[i]
        setupMenu()
        rebuild()
    }

    func toggleZoom() {
        if zoomer.active { zoomer.stop(); applyMode(); return }
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        Task { @MainActor in
            do { try await zoomer.start(screen(Cfg.monitor), factor: Cfg.zoomFactors[Cfg.zoomIndex]) }
            catch { askPermission() }
            applyMode()
        }
    }

    func applyZoomTransform() {
        if let o = zoomer.origin, board == 0 {
            ink.zoomScale = zoomer.factor
            ink.zoomOrigin = o
        } else {
            ink.zoomScale = 1
            ink.zoomOrigin = .zero
        }
        ink.needsDisplay = true
    }

    func applySpot() {
        let s = Cfg.spotSize
        spotView.color = Cfg.palette[Cfg.spotColor]
        spotView.needsDisplay = true
        spot.setContentSize(NSSize(width: s, height: s))
        if Cfg.spotOn {
            moveSpot()
            spot.orderFrontRegardless()
            if spotTimer == nil {
                let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.moveSpot() } }
                RunLoop.main.add(t, forMode: .common)
                spotTimer = t
            }
        } else {
            spot.orderOut(nil)
            spotTimer?.invalidate()
            spotTimer = nil
        }
        highlight("Spot", Cfg.spotOn)
    }

    func moveSpot() {
        let p = NSEvent.mouseLocation, s = spot.frame.size
        let o = NSPoint(x: p.x - s.width / 2, y: p.y - s.height / 2)
        if o != spot.frame.origin { spot.setFrameOrigin(o) }
    }

    func applyMode() {
        ink.page = board
        ink.tool = tool
        ink.cursor = tool == .eraser ? eraserCursor : tool == .highlighter ? highlightCursor : penCursor
        updateFocus()
        (penMode ? ink.cursor : NSCursor.arrow).set() // the pointer may already be over the overlay
        overlay.ignoresMouseEvents = !penMode
        overlay.backgroundColor = board == 1 ? .white : board == 2 ? .black : penMode ? NSColor(white: 0, alpha: 1.0 / 255) : .clear
        zoomer.frozen = penMode
        applyZoomTransform()

        highlight("Pen", penMode && tool == .pen)
        highlight("Highlighter", penMode && tool == .highlighter)
        highlight("Eraser", penMode && tool == .eraser)
        highlight("Board", board != 0)
        highlight("Zoom", zoomer.active)
        highlight("Settings", settingsOpen)
        if let b = buttons["Board"] {
            let t = Lang.t(["Board", "WhiteBoard", "BlackBoard"][board])
            b.attributedTitle = NSAttributedString(string: t, attributes: [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 10)])
        }
        buttonColumn.isHidden = collapsed
        collapseBtn.image = NSImage(systemSymbolName: collapsed ? "chevron.down" : "chevron.up", accessibilityDescription: Lang.t("Collapse"))
        placeBar()
    }

    // macOS only lets the active app set the cursor and take key presses, so HighPen is active while pen mode
    // or the shortcut editor is on, and hands focus back to the app used last (e.g. the slideshow) afterwards.
    func updateFocus() {
        let need = penMode || hotkeyWin != nil
        if need {
            holdingFocus = true
            if !NSApp.isActive { NSApp.activate() }
        } else if holdingFocus {
            holdingFocus = false
            if NSApp.isActive, let p = lastOtherApp {
                NSApp.yieldActivation(to: p)
                p.activate()
            }
        }
    }

    func highlight(_ id: String, _ on: Bool) {
        buttons[id]?.layer?.backgroundColor = (on ? activeBg : idleBg).cgColor
    }

    // ---------- capture (save as PNG + copy to the clipboard) ----------

    // Captures the selected monitor as shown (screen, board, ink, zoom) without the toolbar and spot.
    func capture() {
        guard CGPreflightScreenCaptureAccess() else { askPermission(); return }
        toast?.orderOut(nil)
        let scr = screen(Cfg.monitor)
        let hide = [bar, settings, spot].map { CGWindowID($0.windowNumber) }
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first(where: { $0.displayID == displayID(scr) }) else { throw CocoaError(.featureUnsupported) }
                let filter = SCContentFilter(display: display, excludingWindows: content.windows.filter { hide.contains($0.windowID) })
                let conf = SCStreamConfiguration()
                conf.width = Int(scr.frame.width * scr.backingScaleFactor)
                conf.height = Int(scr.frame.height * scr.backingScaleFactor)
                conf.showsCursor = false
                let img = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: conf)
                guard let png = NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                let dir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("HighPen")
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let f = DateFormatter()
                f.dateFormat = "yyyyMMdd_HHmmss"
                let url = dir.appendingPathComponent("HighPen_" + f.string(from: Date()) + ".png")
                try png.write(to: url)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([NSImage(cgImage: img, size: scr.frame.size)])
                showToast(String(format: Lang.t("Saved"), url.path), seconds: 5) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            } catch {
                showToast(Lang.t("CaptureFailed") + "\n" + error.localizedDescription, seconds: 5)
            }
        }
    }

    func askPermission() {
        CGRequestScreenCaptureAccess()
        showToast(Lang.t("NeedPermission"), seconds: 10) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        }
    }

    // ---------- dialogs (shortcut editor, about) ----------

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
        // centered on the selected monitor
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

    // Every key goes to the shortcut editor while it is open (whichever HighPen window has focus,
    // which can change when the app activates); Esc / Return close the about box.
    func handleKey(_ e: NSEvent) -> Bool {
        if hotkeyWin != nil { editorKey(e); return true }
        if aboutWin != nil && (e.keyCode == kVK_Escape || e.keyCode == kVK_Return) { toggleAbout(); return true }
        return false
    }

    func toggleAbout() {
        if let w = aboutWin { w.orderOut(nil); aboutWin = nil; return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
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
        close.on { [unowned self] _ in self.toggleAbout() }
        fixedSize(close, 300, nil)
        let col = vstack([heading("HighPen v" + version), tagline,
                          row(Lang.t("Author"), "StephenWon", nil),
                          row(Lang.t("Email"), "stepanowon@gmail.com", "mailto:stepanowon@gmail.com"),
                          row(Lang.t("Website"), "github.com/stepanowon/high-pen", repo),
                          row(Lang.t("License"), "MIT License", repo + "/blob/main/LICENSE"),
                          copyright, close])
        col.setCustomSpacing(12, after: tagline)
        col.setCustomSpacing(14, after: copyright)
        let w = dialog(col, keyable: true)
        aboutWin = w
        w.makeKeyAndOrderFront(nil)
    }

    // Lists every action with its shortcut. Click one, then press the new combination.
    // HighPen's own shortcuts are released while the editor is open so pressing them reaches it.
    func showHotkeyEditor() {
        if let w = hotkeyWin { w.makeKeyAndOrderFront(nil); return }
        unregisterHotkeys()
        waiting = nil
        keyBoxes = []
        let rows = vstack([], spacing: 4)
        for (i, a) in actions.enumerated() {
            let name = NSTextField(wrappingLabelWithString: a.title())
            name.textColor = .white
            name.font = .systemFont(ofSize: 12)
            fixedSize(name, 196, nil)
            let box = NSButton(title: "", target: nil, action: nil)
            box.isBordered = false
            box.wantsLayer = true
            box.on { [unowned self] _ in
                self.waiting = i
                self.editorStatus.textColor = .gray
                self.editorStatus.stringValue = Lang.t("HotkeyWaitHint")
                self.refreshEditor()
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
        editorStatus.stringValue = ""
        editorStatus.font = .systemFont(ofSize: 12)
        fixedSize(editorStatus, 360, nil)
        let reset = NSButton(title: Lang.t("ResetDefaults"), target: nil, action: nil)
        reset.on { [unowned self] _ in
            Cfg.hotkeys = [:]
            self.waiting = nil
            self.editorStatus.stringValue = ""
            self.refreshEditor()
        }
        let close = NSButton(title: Lang.t("Close"), target: nil, action: nil)
        close.on { [unowned self] _ in self.closeHotkeyEditor() }
        fixedSize(reset, 176, nil)
        fixedSize(close, 176, nil)
        let btns = NSStackView(views: [reset, close])
        btns.spacing = 8

        let w = dialog(vstack([heading(Lang.t("Hotkeys")), hintText, scroll, editorStatus, btns], spacing: 8), keyable: true)
        hotkeyWin = w
        refreshEditor()
        updateFocus()
        w.makeKeyAndOrderFront(nil)
    }

    func refreshEditor() {
        for (i, a) in actions.enumerated() {
            let c = combo(a.id)
            let t = i == waiting ? Lang.t("PressKeys") : (c.isEmpty ? Lang.t("NoKey") : c)
            keyBoxes[i].attributedTitle = NSAttributedString(string: t, attributes: [
                .foregroundColor: c.isEmpty && i != waiting ? NSColor.gray : NSColor.white, .font: NSFont.systemFont(ofSize: 12)])
            keyBoxes[i].layer?.backgroundColor = (i == waiting ? activeBg : idleBg).cgColor
        }
    }

    func editorKey(_ e: NSEvent) {
        let plain = e.modifierFlags.intersection([.control, .option, .shift, .command]).isEmpty
        let k = Int(e.keyCode)
        guard let i = waiting else {
            if plain && (k == kVK_Escape || k == kVK_Return) { closeHotkeyEditor() }
            return
        }
        func warn(_ t: String) { editorStatus.textColor = rgb(0xFF9F0A); editorStatus.stringValue = t }
        if plain && k == kVK_Escape { waiting = nil; editorStatus.stringValue = ""; refreshEditor(); return }
        if plain && (k == kVK_Delete || k == kVK_ForwardDelete) { editorStatus.stringValue = ""; assign(i, nil); return }
        let h = Hotkey(event: e)
        if h.mods & (controlKey | optionKey | cmdKey) == 0 && Hotkey.fKeys[k] == nil { warn(Lang.t("HotkeyNeedMod")); return }
        if let o = actions.indices.first(where: { $0 != i && hotkey(actions[$0].id)?.same(h) == true }) {
            warn(String(format: Lang.t("HotkeyDup"), actions[o].title()))
            return
        }
        if !available(h) { warn(Lang.t("HotkeyTaken")); return }
        editorStatus.stringValue = ""
        assign(i, h)
    }

    func assign(_ i: Int, _ h: Hotkey?) {
        let a = actions[i]
        if let h = h, h.same(a.def) { Cfg.hotkeys[a.id] = nil } else { Cfg.hotkeys[a.id] = h?.saved ?? "" }
        waiting = nil
        refreshEditor()
    }

    func closeHotkeyEditor() {
        hotkeyWin?.orderOut(nil)
        hotkeyWin = nil
        waiting = nil
        registerHotkeys()
        rebuild() // hints show the new shortcuts
        updateFocus()
        if !failedHotkeys.isEmpty { showToast(Lang.t("HotkeyFail") + "\n" + failedHotkeys.joined(separator: ", "), seconds: 8) }
    }

    // ---------- toast (short message at the bottom of the selected monitor; click closes it) ----------

    func showToast(_ text: String, seconds: Double?, click: (() -> Void)? = nil) {
        toast?.orderOut(nil)
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
            if self?.toast === t { self?.toast = nil }
        }
        t.contentView = box
        let s = box.fittingSize
        let vf = screen(Cfg.monitor).visibleFrame
        t.setFrame(NSRect(x: vf.midX - s.width / 2, y: vf.minY + 40, width: s.width, height: s.height), display: true)
        t.orderFrontRegardless()
        toast = t
        if let sec = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + sec) { [weak self, weak t] in
                t?.orderOut(nil)
                if self?.toast === t { self?.toast = nil }
            }
        }
    }
}

// ---------- self-check: swift-run with --selftest ----------

@MainActor
func selfTest() {
    let v = InkView()
    let s = Stroke(color: .red, width: 4, highlighter: false, pressure: false)
    s.add(CGPoint(x: 0, y: 0), 0.5)
    s.add(CGPoint(x: 100, y: 0), 0.5)
    precondition(s.hits(CGPoint(x: 50, y: 1.5), 0) && !s.hits(CGPoint(x: 50, y: 3), 0), "stroke hit test")
    v.pages[0] = [s]
    v.history[0] = [Edit(added: [s])]
    v.erase(at: CGPoint(x: 50, y: 0))
    v.endErase()
    precondition(v.pages[0].isEmpty && v.history[0].count == 2, "erase is one undo step")
    v.undo()
    precondition(v.pages[0].count == 1, "undo restores the erased stroke")
    v.undo()
    precondition(v.pages[0].isEmpty, "undo removes the drawn stroke")
    v.zoomScale = 2
    v.zoomOrigin = CGPoint(x: 100, y: 50)
    precondition(v.content(CGPoint(x: 40, y: 20)) == CGPoint(x: 120, y: 60), "zoomed input maps back to content")
    let h = Hotkey(mods: controlKey | optionKey, key: kVK_ANSI_P, name: "P")
    precondition(Hotkey(saved: h.saved).map { $0.same(h) && $0.text == "⌃⌥P" } == true, "shortcut round trip")
    precondition(Hotkey(saved: "4096:41::")?.name == ":" && Hotkey(saved: "x") == nil, "shortcut parsing")
    precondition(Hotkey.asciiName(kVK_ANSI_P) == "P", "key names come from the ASCII layout")
    print("selftest ok")
}

MainActor.assumeIsolated {
    if CommandLine.arguments.contains("--selftest") { selfTest(); exit(0) }
    let app = NSApplication.shared
    let controller = Controller()
    app.delegate = controller
    app.setActivationPolicy(.regular)
    app.run()
}
