// Draws the HighPen app icon (the same design as windows/src/make-icon.ps1) on the macOS icon grid
// (824x824 rounded body inside a 1024 canvas, with a soft shadow) and writes an .iconset folder.
//   swiftc make-icon.swift -o make-icon && ./make-icon HighPen.iconset
import AppKit

func rgb(_ v: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: a)
}

func fill(_ ctx: CGContext, _ c: CGColor, _ pts: [CGPoint]) {
    ctx.setFillColor(c)
    ctx.addLines(between: pts)
    ctx.fillPath()
}

func icon(_ n: Int) -> Data {
    let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let s = CGFloat(n) / 1024
    // 1024 grid with y pointing down, like the GDI+ drawing on Windows
    ctx.translateBy(x: 0, y: CGFloat(n))
    ctx.scaleBy(x: s, y: -s)

    // rounded dark body (shadow offsets are in device space: negative = down)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * s), blur: 24 * s, color: rgb(0x000000, 0.35))
    ctx.setFillColor(rgb(0x2B2E33))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 185, cornerHeight: 185, transform: nil))
    ctx.fillPath()
    ctx.restoreGState()

    // the rest in the Windows design units (256 across the body)
    ctx.translateBy(x: 100, y: 100)
    ctx.scaleBy(x: 824 / 256, y: 824 / 256)

    // yellow mouse spot
    ctx.setFillColor(rgb(0xFFD60A, 200 / 255))
    ctx.fillEllipse(in: CGRect(x: 34, y: 100, width: 120, height: 120))

    // pen: body, white cap, wooden tip, dark nib; drawn upright then rotated around its centre
    ctx.translateBy(x: 150, y: 112)
    ctx.rotate(by: 40 * .pi / 180)
    ctx.setFillColor(rgb(0xFF3B30))
    ctx.fill(CGRect(x: -17, y: -100, width: 34, height: 110))
    ctx.setFillColor(rgb(0xFFFFFF))
    ctx.fill(CGRect(x: -17, y: -100, width: 34, height: 20))
    fill(ctx, rgb(0xF2D3A8), [CGPoint(x: -17, y: 10), CGPoint(x: 17, y: 10), CGPoint(x: 0, y: 55)])
    fill(ctx, rgb(0x333333), [CGPoint(x: -6, y: 41), CGPoint(x: 6, y: 41), CGPoint(x: 0, y: 55)])

    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    try icon(pt).write(to: out.appendingPathComponent("icon_\(pt)x\(pt).png"))
    try icon(pt * 2).write(to: out.appendingPathComponent("icon_\(pt)x\(pt)@2x.png"))
}
