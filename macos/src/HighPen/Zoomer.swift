import Cocoa
import CoreMedia
import ScreenCaptureKit

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
    // Set by the user (zoom lock): the view stays put while the pointer moves. Cleared when zoom stops.
    var locked = false
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
        locked = false
        onChange()
    }

    // Can be changed while zoomed; the view updates on the spot.
    func setFactor(_ f: CGFloat) {
        factor = f
        update(force: true)
    }

    func update(force: Bool) {
        guard active, force || !(frozen || locked) else { return }
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
