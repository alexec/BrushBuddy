import SwiftUI

/// Floss slipping between teeth, curving into a C around each tooth and
/// sliding gently up and down. Fingers hold the ends.
struct FlossAnimation: View {
    var zone: MouthZone
    var color: Color = BrushingStage.floss.color

    var body: some View {
        let palette = DrawPalette.standard
        return TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let rect = CGRect(x: size.width * 0.06, y: size.height * 0.10, width: size.width * 0.88, height: size.height * 0.80)
                let layout = FrontMouth.Layout(rect: rect)
                let perGap = 3.0
                // Untimed stage: tour the four quarters in order.
                let zone: MouthZone
                if self.zone == .whole {
                    let quarters: [MouthZone] = [.upperRight, .upperLeft, .lowerLeft, .lowerRight]
                    let gapsPerQuarter = Double(FrontMouth.gapIndices(for: .upperRight).count)
                    zone = quarters[Int(t / (perGap * gapsPerQuarter)) % quarters.count]
                } else {
                    zone = self.zone
                }
                let upper = zone.isUpper
                let gaps = FrontMouth.gapIndices(for: zone)
                guard !gaps.isEmpty else { return }

                let cycle = t.truncatingRemainder(dividingBy: perGap * Double(gaps.count))
                let gapIndex = min(gaps.count - 1, Int(cycle / perGap))
                let inGap = CGFloat(cycle - Double(gapIndex) * perGap) // 0..perGap
                let gap = gaps[gapIndex]
                let gx = layout.gapX(gap)
                // Hug the left tooth for the first half, then the right tooth.
                let hugRight = inGap > CGFloat(perGap / 2)
                let hugged = hugRight ? gap + 1 : gap
                let toothFrame = layout.tooth(hugged, upper: upper)
                let gumY = layout.gumlineY(upper: upper)
                let tipY = upper ? toothFrame.maxY : toothFrame.minY

                var base = ctx
                FrontMouth.draw(in: &base, layout: layout, zone: zone, glow: color, palette: palette)

                // Tint the tooth being hugged.
                let hugPath = Path(roundedRect: toothFrame, cornerRadius: toothFrame.width * 0.32)
                ctx.fill(hugPath, with: .color(color.opacity(0.18)))

                // Insertion depth eases in, then oscillates gently up/down.
                let settle = Draw.smooth((inGap.truncatingRemainder(dividingBy: CGFloat(perGap / 2))) / 0.5)
                let osc = sin(t * 5) * 4
                let depthMax = toothFrame.height * 0.82 + 3          // just under the gumline
                let depth = depthMax * settle + osc
                let insideY = upper ? tipY - depth : tipY + depth
                _ = gumY

                // Finger positions in the mouth interior.
                let fingerY = upper ? tipY + rect.height * 0.16 : tipY - rect.height * 0.16
                let fingerA = CGPoint(x: gx - rect.width * 0.14, y: fingerY)
                let fingerB = CGPoint(x: gx + rect.width * 0.14, y: fingerY)

                // Floss path: finger → gap entry → C-curve around the hugged tooth → back out → finger.
                let bulge = (hugRight ? 1 : -1) * toothFrame.width * 0.55
                var floss = Path()
                floss.move(to: fingerA)
                floss.addLine(to: CGPoint(x: gx - 1.5, y: tipY))
                floss.addCurve(
                    to: CGPoint(x: gx + 1.5, y: tipY),
                    control1: CGPoint(x: gx + bulge, y: insideY - (upper ? -6 : 6)),
                    control2: CGPoint(x: gx + bulge, y: insideY - (upper ? 6 : -6))
                )
                floss.addLine(to: fingerB)
                ctx.stroke(floss, with: .color(.white.opacity(0.95)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                ctx.stroke(floss, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))

                // Fingertips holding the floss.
                for f in [fingerA, fingerB] {
                    let r: CGFloat = 12
                    ctx.fill(Path(ellipseIn: CGRect(x: f.x - r, y: f.y - r, width: r * 2, height: r * 2)), with: .color(palette.skin))
                    ctx.stroke(Path(ellipseIn: CGRect(x: f.x - r, y: f.y - r, width: r * 2, height: r * 2)), with: .color(palette.gumDark.opacity(0.5)), lineWidth: 1)
                    for k in 0..<3 {
                        let y = f.y - 5 + CGFloat(k) * 4
                        var wrap = Path()
                        wrap.move(to: CGPoint(x: f.x - 8, y: y))
                        wrap.addLine(to: CGPoint(x: f.x + 8, y: y))
                        ctx.stroke(wrap, with: .color(.white.opacity(0.8)), lineWidth: 1.2)
                    }
                }

                // Up/down motion arrows next to the hugged tooth.
                let arrowX = hugRight ? toothFrame.maxX + 8 : toothFrame.minX - 8
                let arrowMid = (tipY + insideY) / 2
                var arrow = Path()
                arrow.move(to: CGPoint(x: arrowX, y: arrowMid - 10))
                arrow.addLine(to: CGPoint(x: arrowX, y: arrowMid + 10))
                arrow.move(to: CGPoint(x: arrowX - 3, y: arrowMid - 7))
                arrow.addLine(to: CGPoint(x: arrowX, y: arrowMid - 10))
                arrow.addLine(to: CGPoint(x: arrowX + 3, y: arrowMid - 7))
                arrow.move(to: CGPoint(x: arrowX - 3, y: arrowMid + 7))
                arrow.addLine(to: CGPoint(x: arrowX, y: arrowMid + 10))
                arrow.addLine(to: CGPoint(x: arrowX + 3, y: arrowMid + 7))
                ctx.stroke(arrow, with: .color(color.opacity(0.7 + 0.3 * sin(t * 5))), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityLabel("Animation of floss curving around each tooth in a C shape")
    }
}
