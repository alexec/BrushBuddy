import SwiftUI

/// Top-down mouth with the current quadrant glowing while a toothbrush makes
/// small circles over it. For the tongue step the brush sweeps back to front.
struct BrushAnimation: View {
    var zone: MouthZone
    var color: Color = BrushingStage.brush.color

    var body: some View {
        let palette = DrawPalette.standard
        return TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let rect = CGRect(x: size.width * 0.05, y: size.height * 0.05, width: size.width * 0.90, height: size.height * 0.90)
                let layout = ArchMouth.Layout(rect: rect)

                var base = ctx
                ArchMouth.draw(in: &base, layout: layout, zone: zone, glow: color, palette: palette)

                let headSize = CGSize(width: layout.toothSize.width * 1.15, height: layout.toothSize.height * 2.3)

                if zone == .tongue {
                    // Sweep from the back of the tongue to the tip, lift, repeat.
                    let period = 1.6
                    let phase = CGFloat((t / period).truncatingRemainder(dividingBy: 1))
                    let tr = layout.tongueRect
                    let sweep = Draw.smooth(phase / 0.75)
                    let lift = phase > 0.75 ? Draw.smooth((phase - 0.75) / 0.25) : 0
                    let x = tr.midX + sin(t * 9) * 3
                    let y = Draw.lerp(tr.minY + tr.height * 0.15, tr.maxY - tr.height * 0.15, sweep)
                    let head = CGPoint(x: x + lift * 10, y: y - lift * 14)
                    // Trail behind the brush.
                    if lift == 0 {
                        var trail = Path()
                        trail.move(to: CGPoint(x: x, y: tr.minY + tr.height * 0.15))
                        trail.addLine(to: CGPoint(x: x, y: y))
                        ctx.stroke(trail, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: headSize.width * 0.9, lineCap: .round))
                    }
                    Draw.toothbrush(in: &ctx, head: head, handleDirection: CGVector(dx: 0.35, dy: 1).normalized, headSize: headSize, color: color)
                } else {
                    let teeth = ArchMouth.highlightedTeeth(zone: zone, layout: layout)
                    guard !teeth.isEmpty else { return }
                    // Visit each tooth in turn, making small circles on each.
                    let perTooth = 1.1
                    let cycle = t.truncatingRemainder(dividingBy: perTooth * Double(teeth.count))
                    let idx = min(teeth.count - 1, Int(cycle / perTooth))
                    let frac = CGFloat(cycle - Double(idx) * perTooth) / CGFloat(perTooth)
                    let from = teeth[max(0, idx - 1)]
                    let to = teeth[idx]
                    let travel = Draw.smooth(frac / 0.3)
                    let centre = idx == 0 ? to : Draw.lerp(from, to, travel)
                    let circleR: CGFloat = layout.toothSize.width * 0.35
                    let head = CGPoint(x: centre.x + cos(t * 11) * circleR, y: centre.y + sin(t * 11) * circleR)

                    // Handle comes from below and from the side the quadrant is on.
                    let isRight = zone.isRight ?? true
                    let dir = CGVector(dx: isRight ? 0.75 : -0.75, dy: 1).normalized
                    // 45° hint ring where bristles meet the gum.
                    ctx.stroke(Path(ellipseIn: CGRect(x: centre.x - circleR * 1.8, y: centre.y - circleR * 1.8, width: circleR * 3.6, height: circleR * 3.6)), with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))

                    Draw.toothbrush(in: &ctx, head: head, handleDirection: dir, headSize: headSize, color: color, rotation: 0.15)

                    // Foam bubbles.
                    for k in 0..<5 {
                        let seed = Draw.hash(k * 17 + 3)
                        let life = CGFloat((t * 1.3 + Double(seed)).truncatingRemainder(dividingBy: 1))
                        let angle = seed * .pi * 2 + CGFloat(t) * 0.5
                        let dist = 6 + life * 16
                        let p = CGPoint(x: centre.x + cos(angle) * dist, y: centre.y + sin(angle) * dist - life * 6)
                        let r = 2 + seed * 3 * (1 - life)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(Double(0.9 - life * 0.8))))
                    }
                    // Sparkles on teeth already visited this pass.
                    for (i, p) in teeth.enumerated() where i < idx {
                        let pulse = 0.5 + 0.5 * sin(t * 5 + Double(i) * 1.3)
                        Draw.sparkle(in: &ctx, at: CGPoint(x: p.x, y: p.y - layout.toothSize.height * 0.1), size: 3 + 3 * pulse, color: .white, opacity: 0.9)
                    }
                }
            }
        }
        .accessibilityLabel(zone == .tongue ? "Animation of brushing the tongue from back to front" : "Animation of a toothbrush making gentle circles over the highlighted quarter of the mouth")
    }
}

extension CGVector {
    var normalized: CGVector {
        let len = max(0.0001, sqrt(dx * dx + dy * dy))
        return CGVector(dx: dx / len, dy: dy / len)
    }
}
