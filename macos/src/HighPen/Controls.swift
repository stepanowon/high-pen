import Cocoa

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

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
