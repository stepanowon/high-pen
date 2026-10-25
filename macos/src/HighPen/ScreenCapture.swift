import Cocoa
import ScreenCaptureKit

// ---------- capture (save as PNG + copy to the clipboard) ----------

enum ScreenCapture {
    // Captures the monitor as shown (screen, board, ink, zoom) without the given windows, saves it
    // in Pictures/HighPen and copies it to the clipboard. Returns the saved file.
    @MainActor
    static func save(_ scr: NSScreen, hiding hide: [CGWindowID]) async throws -> URL {
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
        return url
    }
}
