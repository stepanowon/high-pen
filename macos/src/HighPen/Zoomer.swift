import Cocoa
import CoreMedia
import ScreenCaptureKit

// ---------- zoom ----------

// Live zoom of one monitor: ScreenCaptureKit streams the screen (without HighPen's own windows) and a
// click-through window shows part of it enlarged. The real pointer stays on the unzoomed content, hidden, and
// the pointer is drawn enlarged over the image, so a click lands exactly on what the pointer is shown over.
// The view holds still until the pointer reaches one of its edges and then moves along with the pointer.
// HighPen's own windows are not enlarged and the ink overlay takes input in display coordinates, so over them
// (and whenever direct is set: pen mode, a break, a capture) the real pointer is shown instead, at its position on the display.
@MainActor
final class Zoomer: NSObject, SCStreamOutput, SCStreamDelegate {
    private let window = Panel(level: 0, clickThrough: true)
    private let view = NSView()
    // The drawn pointer, in a window above the ink, the spot and the click rings, as the real pointer would be.
    private let pointerWindow = Panel(level: 3, clickThrough: true)
    private let pointer = CALayer()
    private var stream: SCStream?
    // between start being called and the stream running, so a second start does not open a second stream
    private var starting = false
    // stop was called while starting: the stream is closed as soon as it runs
    private var cancelled = false
    private var timer: Timer?
    private var frame = NSRect.zero
    private(set) var factor: CGFloat = 2
    // Set by the user (zoom lock): the view stays put while the pointer moves. Cleared when zoom stops.
    var locked = false
    // The real pointer must be shown and the view stays put (pen mode: drawing on the view; something covers the image).
    var direct = false { didSet { if direct != oldValue { update(force: true) } } }
    // Bottom-left of the area being shown, in screen-local points (nil = zoom off).
    private(set) var origin: CGPoint?
    var onChange: () -> Void = {}
    // The system stopped the stream (display gone, permission withdrawn).
    var onStop: () -> Void = {}
    var active: Bool { stream != nil }

    // True: the real pointer is visible and its position is the position on the display.
    // False: it is hidden, on the content, and drawn over the image.
    private var pointerDirect = true
    // HighPen's windows made click-through while the pointer is drawn: the hidden pointer can pass over them
    // although it is shown somewhere else.
    private var madeClickThrough: [NSWindow] = []
    private var lastPointer = CGPoint(x: -1, y: -1)
    // updates skipped since HighPen's windows were last looked at: a window opening under a resting pointer is noticed a little later
    private var updatesSinceScan = 0
    private var cursorSize = CGSize.zero, cursorHotSpot = CGPoint.zero
    // Holding the real pointer on the monitor's edge over a HighPen window (the toolbar along that edge) moves the
    // view: after about 200 ms, so a pointer flung at the bar moves nothing, and then about 1.5 s across the whole view.
    private static let edgeHold = 12, edgeCross: CGFloat = 90
    private var edgeHeld = 0

    override init() {
        super.init()
        // macOS only lets the active app hide the pointer unless the connection asks otherwise (private, but long stable)
        let c = _CGSDefaultConnection()
        _ = CGSSetConnectionProperty(c, c, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
        view.wantsLayer = true
        view.layer?.contentsGravity = .resize
        window.contentView = view
        let pv = NSView()
        pv.wantsLayer = true
        pointer.anchorPoint = .zero
        pointer.actions = ["contents": NSNull(), "position": NSNull(), "bounds": NSNull()] // no sliding
        pv.layer?.addSublayer(pointer)
        pointerWindow.contentView = pv
        pointerWindow.animationBehavior = .none // gone at once, not faded out into a capture
    }

    func start(_ screen: NSScreen, factor: CGFloat) async throws {
        guard !active, !starting else { return }
        starting = true
        cancelled = false
        defer { starting = false }
        guard let (content, display, conf) = try await ScreenCapture.setup(screen) else { return }
        let me = content.applications.filter { $0.processID == getpid() }
        let filter = SCContentFilter(display: display, excludingApplications: me, exceptingWindows: [])
        conf.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        conf.queueDepth = 4
        let s = SCStream(filter: filter, configuration: conf, delegate: self)
        try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
        try await s.startCapture()
        // turned off (or the monitor changed) meanwhile
        if cancelled { try? await s.stopCapture(); return }
        stream = s
        frame = screen.frame
        self.factor = factor
        // the content under the pointer stays under the pointer when zoom starts
        let p = clamp(NSEvent.mouseLocation)
        origin = CGPoint(x: (p.x - frame.minX) * (1 - 1 / factor), y: (p.y - frame.minY) * (1 - 1 / factor))
        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
        pointerWindow.setFrame(frame, display: false)
        update(force: true)
        timer = repeatingTimer(1.0 / 60) { [weak self] in self?.update(force: false) }
    }

    func stop() {
        if starting { cancelled = true }
        guard let s = stream else { return }
        if !pointerDirect { showPointer(direct: true, at: nil) } // left on the content it was over
        restoreClicks()
        stream = nil
        timer?.invalidate()
        timer = nil
        s.stopCapture { _ in }
        window.orderOut(nil)
        view.layer?.contents = nil
        origin = nil
        locked = false
        onChange()
    }

    nonisolated func stream(_ s: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            guard s === self.stream else { return }
            self.stop()
            self.onStop()
        }
    }

    // Can be changed while zoomed; the content the pointer is shown over stays there.
    func setFactor(_ f: CGFloat) {
        if let o = origin {
            let at = clamp(shown(NSEvent.mouseLocation)) - frame.origin
            origin = CGPoint(x: o.x + at.x * (1 / factor - 1 / f), y: o.y + at.y * (1 / factor - 1 / f))
        }
        factor = f
        update(force: true)
    }

    // Where a pointer position appears on the display: windows outside the enlarged image, such as the spot
    // and the click rings, follow the pointer with this.
    func shown(_ p: CGPoint) -> CGPoint {
        guard let o = origin, !pointerDirect else { return p }
        return clamp(Zoomer.toDisplay(p - frame.origin, o, factor) + frame.origin)
    }

    func update(force: Bool) {
        guard active, var o = origin else { return }
        let size = frame.size, w = size.width / factor, h = size.height / factor
        var p = NSEvent.mouseLocation
        updatesSinceScan += 1
        if p == lastPointer && !force && updatesSinceScan < 8 && edgeHeld == 0 { return }
        updatesSinceScan = 0
        // the pointer stays on the zoomed monitor; a hidden one that got away would click somewhere unseen
        // ponytail: put back on the next update, so for up to a frame it can be on the next monitor; an event tap would close that gap
        if !pointerDirect && clamp(p) != p { p = clamp(p); warp(p) }
        var covered = ownWindow(at: pointerDirect ? p : shown(p)) != nil
        // a held button stays with the pointer mode it was pressed in, so a drag is not cut off halfway
        if covered != pointerDirect && NSEvent.pressedMouseButtons != 0 { covered = pointerDirect }
        let direct = self.direct || covered
        if direct != pointerDirect {
            p = direct ? shown(p) : Zoomer.toContent(clamp(p) - frame.origin, o, factor) + frame.origin
            showPointer(direct: direct, at: p)
            if direct { restoreClicks() }
        }
        if !direct {
            letClicksThrough()
            let local = p - frame.origin
            if locked {
                // the pointer cannot leave the part being shown: outside it there would be no pointer to see
                let k = CGPoint(x: min(max(local.x, o.x), o.x + w - 1), y: min(max(local.y, o.y), o.y + h - 1))
                if k != local { p = k + frame.origin; warp(p) }
            } else {
                o = CGPoint(x: Zoomer.pan(o.x, w, local.x), y: Zoomer.pan(o.y, h, local.y))
            }
        }
        if direct && covered && !self.direct && !locked { o = panFromEdge(p, o, w, h) } else { edgeHeld = 0 }
        o = CGPoint(x: min(max(o.x, 0), size.width - w), y: min(max(o.y, 0), size.height - h))
        lastPointer = p
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if o != origin || force {
            origin = o
            view.layer?.contentsRect = CGRect(x: o.x / size.width, y: o.y / size.height, width: 1 / factor, height: 1 / factor)
            onChange()
        }
        if !direct { drawPointer(at: shown(p) - frame.origin) }
        CATransaction.commit()
    }

    // A HighPen window along the monitor's edge keeps the hidden pointer from getting to the edge of the view.
    private func panFromEdge(_ p: CGPoint, _ o: CGPoint, _ w: CGFloat, _ h: CGFloat) -> CGPoint {
        let dx: CGFloat = p.x <= frame.minX ? -1 : p.x >= frame.maxX - 1 ? 1 : 0
        let dy: CGFloat = p.y <= frame.minY + 1 ? -1 : p.y >= frame.maxY ? 1 : 0
        if dx == 0 && dy == 0 { edgeHeld = 0; return o }
        if edgeHeld < Zoomer.edgeHold { edgeHeld += 1; return o }
        return CGPoint(x: o.x + dx * max(1, w / Zoomer.edgeCross), y: o.y + dy * max(1, h / Zoomer.edgeCross))
    }

    // The start of the view along one axis, moved only as far as it takes to keep the pointer inside.
    static func pan(_ start: CGFloat, _ size: CGFloat, _ pointer: CGFloat) -> CGFloat {
        if pointer < start { return pointer }
        if pointer > start + size - 1 { return pointer - size + 1 }
        return start
    }

    // Screen-local content point <-> screen-local display point, for a view at origin o.
    static func toDisplay(_ p: CGPoint, _ o: CGPoint, _ f: CGFloat) -> CGPoint { CGPoint(x: (p.x - o.x) * f, y: (p.y - o.y) * f) }
    static func toContent(_ p: CGPoint, _ o: CGPoint, _ f: CGFloat) -> CGPoint { CGPoint(x: o.x + p.x / f, y: o.y + p.y / f) }

    // A point on the zoomed monitor. Pointer positions there run from minX to maxX - 1 but from minY + 1 to maxY
    // (the top row of pixels is at maxY).
    private func clamp(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, frame.minX), frame.maxX - 1), y: min(max(p.y, frame.minY + 1), frame.maxY))
    }

    // HighPen's window that takes clicks at a point on the display (other than the zoom itself).
    private func ownWindow(at p: CGPoint) -> NSWindow? {
        NSApp.windows.first { $0 !== window && $0.isVisible && (!$0.ignoresMouseEvents || madeClickThrough.contains($0)) && $0.frame.contains(p) }
    }

    private func letClicksThrough() {
        madeClickThrough.removeAll { w in
            if w.isVisible { return false }
            w.ignoresMouseEvents = false // closed: not kept alive here
            return true
        }
        for w in NSApp.windows where w !== window && w.isVisible && !w.ignoresMouseEvents {
            w.ignoresMouseEvents = true
            madeClickThrough.append(w)
        }
    }

    private func restoreClicks() {
        for w in madeClickThrough { w.ignoresMouseEvents = false }
        madeClickThrough = []
    }

    // Shows the real pointer at p, or hides it on the content at p and draws it in the image.
    private func showPointer(direct: Bool, at p: CGPoint?) {
        if let p = p { warp(p) }
        let d = CGMainDisplayID()
        _ = direct ? CGDisplayShowCursor(d) : CGDisplayHideCursor(d)
        if direct { pointerWindow.orderOut(nil) } else { cursorAge = 8; pointerWindow.orderFrontRegardless() }
        pointerDirect = direct
    }

    // The pointer image, enlarged, with its hot spot at p (screen-local display point). Its shape is looked up
    // again every few updates and when the factor changes, not on every move.
    private var cursorAge = 0, cursorFactor: CGFloat = 0
    private func drawPointer(at p: CGPoint) {
        cursorAge += 1
        if cursorAge >= 8 || cursorFactor != factor, let c = NSCursor.currentSystem {
            // the sharpest image for the enlarged size
            var r = CGRect(origin: .zero, size: c.image.size)
            r.size.width *= factor * window.backingScaleFactor
            r.size.height *= factor * window.backingScaleFactor
            pointer.contents = c.image.cgImage(forProposedRect: &r, context: nil, hints: nil)
            cursorSize = c.image.size
            cursorHotSpot = c.hotSpot
            cursorAge = 0
            cursorFactor = factor
        }
        let s = cursorSize, h = cursorHotSpot
        pointer.frame = CGRect(x: p.x - h.x * factor, y: p.y - (s.height - h.y) * factor, width: s.width * factor, height: s.height * factor)
    }

    // Moves the pointer (bottom-left global coordinates) without the usual short freeze of mouse input after a warp.
    private func warp(_ p: CGPoint) {
        CGWarpMouseCursorPosition(CGPoint(x: p.x, y: NSScreen.screens[0].frame.maxY - p.y))
        CGAssociateMouseAndMouseCursorPosition(1)
    }

    nonisolated func stream(_ s: SCStream, didOutputSampleBuffer sb: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let pb = CMSampleBufferGetImageBuffer(sb),
              let surface = CVPixelBufferGetIOSurface(pb)?.takeUnretainedValue() else { return }
        MainActor.assumeIsolated {
            // frames already queued when zoom stopped would put the (full-size) screen image back on the hidden layer
            guard s === stream else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            view.layer?.contents = surface
            CATransaction.commit()
        }
    }
}

private func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
private func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }

@_silgen_name("_CGSDefaultConnection") private func _CGSDefaultConnection() -> Int32
@_silgen_name("CGSSetConnectionProperty") private func CGSSetConnectionProperty(_ c: Int32, _ t: Int32, _ key: CFString, _ value: CFTypeRef) -> Int32
