import Cocoa

// ---------- break timer (a countdown over the whole selected monitor) ----------

// The break lengths offered, in minutes.
enum BreakTimes {
    static let min = 5, max = 120, step = 5
    static let presets = [10, 15, 60, 90]

    // Rounds to the nearest step and keeps it in range.
    static func clamp(_ minutes: Int) -> Int {
        let m = Int((Double(minutes) / Double(step)).rounded()) * step
        return Swift.max(min, Swift.min(max, m))
    }

    // 90 -> "1시간 30분" / "1時間30分" / "1 h 30 min"
    static func label(_ minutes: Int) -> String {
        if minutes < 60 { return String(format: Lang.t("Minutes"), minutes) }
        if minutes % 60 == 0 { return String(format: Lang.t("Hours"), minutes / 60) }
        return String(format: Lang.t("HoursMinutes"), minutes / 60, minutes % 60)
    }

    // 599 -> "09:59", 3600 -> "1:00:00"
    static func clock(_ secs: Int) -> String {
        secs >= 3600 ? String(format: "%d:%02d:%02d", secs / 3600, secs / 60 % 60, secs % 60)
                     : String(format: "%02d:%02d", secs / 60, secs % 60)
    }
}

// The title, the time and when the class resumes, scaled together to fill the middle half of the monitor's height.
final class BreakView: NSView {
    var lines: [(String, CGFloat, NSFont.Weight, NSColor)] = []

    override func draw(_ r: NSRect) {
        rgb(0x121418).withAlphaComponent(0xE6 / 255.0).setFill()
        bounds.fill()
        let texts = lines.map { s, size, weight, color in
            NSAttributedString(string: s, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight), .foregroundColor: color])
        }
        let sizes = texts.map { $0.size() }
        let w = sizes.map(\.width).max() ?? 0, h = sizes.map(\.height).reduce(0, +)
        guard w > 0, h > 0 else { return }
        let k = min(bounds.width / w, bounds.height / 2 / h)
        var y = bounds.midY + h * k / 2
        NSGraphicsContext.saveGraphicsState()
        for (t, s) in zip(texts, sizes) {
            y -= s.height * k
            let x = bounds.midX - s.width * k / 2
            let at = NSAffineTransform()
            at.translateX(by: x, yBy: y)
            at.scale(by: k)
            at.concat()
            t.draw(at: .zero)
            at.invert()
            at.concat()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

// Click-through: the presenter can keep working, and the toolbar stays above it to stop the break.
@MainActor
final class BreakTimer {
    let window = Panel(level: 2, clickThrough: true)
    private let view = BreakView()
    private var timer: Timer?
    private var end = Date()
    var running: Bool { timer != nil }

    init() { window.contentView = view }

    func start(_ minutes: Int) {
        end = Date().addingTimeInterval(TimeInterval(minutes * 60))
        refresh()
        window.orderFrontRegardless()
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.refresh() } }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        window.orderOut(nil)
    }

    // Stays up at 00:00 once the break is over, until it is stopped.
    private func refresh() {
        let left = end.timeIntervalSinceNow
        let over = left <= 0
        // round up, so the display reaches 00:00 exactly when the break ends
        let secs = over ? 0 : Int(left.rounded(.up))
        let color = over ? rgb(0xFF453A) : left <= 60 ? rgb(0xFF9F0A) : .white
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        // the resume line stays (blank) once over, so the time does not jump
        let resume = over ? " " : String(format: Lang.t("BreakEnds"), f.string(from: end))
        view.lines = [(Lang.t(over ? "BreakOver" : "BreakTitle"), 40, .regular, .white),
                      (BreakTimes.clock(secs), 200, .semibold, color),
                      (resume, 30, .regular, .gray)]
        view.needsDisplay = true
    }
}
