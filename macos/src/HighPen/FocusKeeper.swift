import Cocoa

// ---------- focus ----------

// macOS only lets the active app set the cursor and take key presses, so HighPen is active while it needs
// them (pen mode, the shortcut editor) and hands focus back to the app used last (e.g. the slideshow) afterwards.
@MainActor
final class FocusKeeper {
    private var lastOtherApp: NSRunningApplication?
    private var holding = false

    func start() {
        lastOtherApp = NSWorkspace.shared.frontmostApplication.flatMap { $0 == .current ? nil : $0 }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [unowned self] n in
            let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated { if let a = app, a != .current { self.lastOtherApp = a } }
        }
    }

    func update(need: Bool) {
        if need {
            holding = true
            if !NSApp.isActive { NSApp.activate() }
        } else if holding {
            holding = false
            if NSApp.isActive, let p = lastOtherApp {
                NSApp.yieldActivation(to: p)
                p.activate()
            }
        }
    }
}
