import Cocoa

// Entry point. Composition happens in Controller; --selftest runs the checks instead of the app.
MainActor.assumeIsolated {
    if CommandLine.arguments.contains("--selftest") { selfTest(); exit(0) }
    let app = NSApplication.shared
    let controller = Controller()
    app.delegate = controller
    app.setActivationPolicy(.regular)
    app.run()
}
