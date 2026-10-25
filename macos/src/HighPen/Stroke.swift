import Cocoa

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
