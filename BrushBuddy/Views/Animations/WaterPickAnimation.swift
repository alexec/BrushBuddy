import SwiftUI

/// A water flosser tracing the gumline, pausing between teeth, with a jet of
/// droplets and a splash. The active row glows.
struct WaterPickAnimation: View {
    var zone: MouthZone
    @Environment(\.visualStyle) private var style
    var color: Color = BrushingStage.waterPick.color

    var body: some View {
        let palette = DrawPalette.forStyle(style)
        return TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let rect = CGRect(x: size.width * 0.06, y: size.height * 0.10, width: size.width * 0.88, height: size.height * 0.80)
                let layout = FrontMouth.Layout(rect: rect)
                // Untimed stage: alternate upper and lower rows every few seconds.
                let zone: MouthZone = self.zone == .whole
                    ? (Int(t / 9).isMultiple(of: 2) ? .upper : .lower)
                    : self.zone
                let upper = zone.isUpper

                // Which gaps have been cleaned already in this sweep get a sparkle.
                let gaps = FrontMouth.gapIndices(for: zone)
                let perGap = 1.4
                let sweep = t.truncatingRemainder(dividingBy: perGap * Double(gaps.count + 1))
                let gapPosition = sweep / perGap                       // continuous index
                let gapIndex = min(gaps.count - 1, Int(gapPosition))
                let frac = CGFloat(gapPosition - Double(Int(gapPosition)))
                // Move quickly to the gap, then linger.
                let move = Draw.smooth(frac / 0.35)
                let fromX = gapIndex == 0 ? layout.gapX(gaps[0]) - rect.width * 0.08 : layout.gapX(gaps[gapIndex - 1])
                let toX = layout.gapX(gaps[gapIndex])
                let tipX = Draw.lerp(fromX, toX, move)
                let gumY = layout.gumlineY(upper: upper)

                var base = ctx
                FrontMouth.draw(in: &base, layout: layout, zone: zone, glow: color, palette: palette)

                // Sparkles on cleaned gaps.
                for (i, g) in gaps.enumerated() where i < gapIndex {
                    let age = CGFloat(gapPosition) - CGFloat(i) - 1
                    let pulse = 0.55 + 0.45 * sin(t * 6 + Double(i))
                    let sparkleY = upper ? gumY + rect.height * 0.10 : gumY - rect.height * 0.10
                    Draw.sparkle(in: &ctx, at: CGPoint(x: layout.gapX(g), y: sparkleY), size: 5 + 2 * pulse, color: .white, opacity: min(1, max(0, 1.3 - age * 0.25)))
                }

                // Water jet: the tip sits in the mouth interior pointing at the gumline.
                let tipY = upper ? gumY + rect.height * 0.30 : gumY - rect.height * 0.30
                let tip = CGPoint(x: tipX, y: tipY)
                let target = CGPoint(x: tipX, y: gumY + (upper ? rect.height * 0.02 : -rect.height * 0.02))

                // Droplets streaming from tip to gumline.
                for k in 0..<7 {
                    let phase = CGFloat((t * 2.2 + Double(k) / 7).truncatingRemainder(dividingBy: 1))
                    let p = Draw.lerp(tip, target, phase)
                    let r = 3.2 - phase * 1.4
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Theme.water.opacity(0.9)))
                }
                // Core stream.
                var stream = Path()
                stream.move(to: tip)
                stream.addLine(to: target)
                ctx.stroke(stream, with: .color(Theme.water.opacity(0.35)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                // Splash droplets at the gumline.
                for k in 0..<6 {
                    let seed = Draw.hash(k * 31 + 7)
                    let life = CGFloat((t * 1.6 + Double(seed)).truncatingRemainder(dividingBy: 1))
                    let dir: CGFloat = k % 2 == 0 ? 1 : -1
                    let dx = dir * (8 + seed * 18) * life
                    let dy = (upper ? 1 : -1) * (10 * life - 22 * life * life) * -1
                    let p = CGPoint(x: target.x + dx, y: target.y + dy)
                    let r = 2.2 * (1 - life)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Theme.water.opacity(Double(1 - life))))
                }

                // The flosser: a slim white handle with a coloured tip, angled 90° to the gum.
                let handleLength = rect.height * 0.42
                let handleEnd = CGPoint(x: tipX + rect.width * 0.12, y: upper ? tipY + handleLength : tipY - handleLength)
                var handle = Path()
                handle.move(to: CGPoint(x: tipX, y: upper ? tipY + 6 : tipY - 6))
                handle.addQuadCurve(to: handleEnd, control: CGPoint(x: tipX, y: upper ? tipY + handleLength * 0.7 : tipY - handleLength * 0.7))
                ctx.stroke(handle, with: .color(.white), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                ctx.stroke(handle, with: .color(color.opacity(0.35)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                ctx.stroke(handle, with: .color(.white), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                // Power button.
                let buttonP = CGPoint(x: tipX + rect.width * 0.03, y: upper ? tipY + handleLength * 0.45 : tipY - handleLength * 0.45)
                ctx.fill(Path(ellipseIn: CGRect(x: buttonP.x - 3, y: buttonP.y - 3, width: 6, height: 6)), with: .color(color))
                // Tip nozzle.
                var nozzle = Path()
                nozzle.move(to: CGPoint(x: tipX, y: upper ? tipY + 8 : tipY - 8))
                nozzle.addLine(to: tip)
                ctx.stroke(nozzle, with: .color(color), style: StrokeStyle(lineWidth: 5, lineCap: .round))

                // "90°" hint near the tip.
                let label = Text("90°").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(color)
                ctx.draw(label, at: CGPoint(x: tipX + 22, y: upper ? tipY - 2 : tipY + 2))
            }
        }
        .accessibilityLabel("Animation of a water flosser tracing the gumline")
    }
}
