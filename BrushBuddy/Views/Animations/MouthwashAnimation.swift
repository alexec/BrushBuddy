import SwiftUI

/// Refined: mouthwash sloshing inside a stylised cavity. Kids: a face with
/// puffed cheeks swishing from side to side.
struct MouthwashAnimation: View {
    @Environment(\.visualStyle) private var style
    var color: Color = BrushingStage.mouthwash.color

    var body: some View {
        if style == .kids {
            MouthwashFaceAnimation(color: color)
        } else {
            MouthwashVesselAnimation(color: color)
        }
    }
}

struct MouthwashVesselAnimation: View {
    var color: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let slosh = CGFloat(sin(t * 2.4))   // -1 … 1

                // Cavity: flat top, deep rounded bottom.
                let cav = CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.64, height: h * 0.56)
                var cavity = Path()
                cavity.move(to: CGPoint(x: cav.minX, y: cav.minY))
                cavity.addLine(to: CGPoint(x: cav.maxX, y: cav.minY))
                cavity.addLine(to: CGPoint(x: cav.maxX, y: cav.midY))
                cavity.addCurve(to: CGPoint(x: cav.minX, y: cav.midY),
                                control1: CGPoint(x: cav.maxX, y: cav.maxY + cav.height * 0.25),
                                control2: CGPoint(x: cav.minX, y: cav.maxY + cav.height * 0.25))
                cavity.closeSubpath()
                ctx.fill(cavity, with: .color(DrawPalette.forStyle(.refined).mouthInterior))

                // Liquid, clipped to the cavity, tilting with the slosh.
                var liquidCtx = ctx
                liquidCtx.clip(to: cavity)
                var liquid = Path()
                let baseY = cav.minY + cav.height * 0.42
                let tilt = slosh * cav.height * 0.22
                let stepsN = 32
                liquid.move(to: CGPoint(x: cav.minX - 10, y: baseY + tilt))
                for s in 0...stepsN {
                    let fx = CGFloat(s) / CGFloat(stepsN)
                    let x = cav.minX - 10 + (cav.width + 20) * fx
                    let y = baseY + tilt - 2 * tilt * fx + sin(fx * .pi * 2.5 + CGFloat(t) * 6) * 3
                    liquid.addLine(to: CGPoint(x: x, y: y))
                }
                liquid.addLine(to: CGPoint(x: cav.maxX + 10, y: cav.maxY + cav.height))
                liquid.addLine(to: CGPoint(x: cav.minX - 10, y: cav.maxY + cav.height))
                liquid.closeSubpath()
                liquidCtx.fill(liquid, with: .linearGradient(
                    Gradient(colors: [color.opacity(0.95), color.opacity(0.55)]),
                    startPoint: CGPoint(x: cav.midX, y: baseY - 20),
                    endPoint: CGPoint(x: cav.midX, y: cav.maxY + cav.height * 0.2)))
                // Highlight along the surface.
                var surface = Path()
                for s in 0...stepsN {
                    let fx = CGFloat(s) / CGFloat(stepsN)
                    let x = cav.minX - 10 + (cav.width + 20) * fx
                    let y = baseY + tilt - 2 * tilt * fx + sin(fx * .pi * 2.5 + CGFloat(t) * 6) * 3
                    if s == 0 { surface.move(to: CGPoint(x: x, y: y)) } else { surface.addLine(to: CGPoint(x: x, y: y)) }
                }
                liquidCtx.stroke(surface, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                // Bubbles drifting up.
                for k in 0..<10 {
                    let seed = Draw.hash(k * 13 + 5)
                    let life = CGFloat((t * 0.6 + Double(seed)).truncatingRemainder(dividingBy: 1))
                    let x = cav.minX + cav.width * (0.15 + seed * 0.7) + slosh * 14
                    let y = cav.maxY - life * cav.height * 0.7
                    let r = 1.2 + seed * 2.4
                    liquidCtx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(Double(0.6 - life * 0.5))))
                }

                // Outline.
                ctx.stroke(cavity, with: .color(color.opacity(0.55)), style: StrokeStyle(lineWidth: 2, lineJoin: .round))

                // Swish direction.
                let arrowY = cav.maxY + cav.height * 0.36
                let dir: CGFloat = slosh >= 0 ? 1 : -1
                let ax = w / 2 - dir * 28
                var arrow = Path()
                arrow.move(to: CGPoint(x: ax, y: arrowY))
                arrow.addLine(to: CGPoint(x: ax + dir * 56, y: arrowY))
                arrow.move(to: CGPoint(x: ax + dir * 47, y: arrowY - 6))
                arrow.addLine(to: CGPoint(x: ax + dir * 56, y: arrowY))
                arrow.addLine(to: CGPoint(x: ax + dir * 47, y: arrowY + 6))
                ctx.stroke(arrow, with: .color(color.opacity(0.9)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityLabel("Animation of mouthwash swishing from side to side")
    }
}

/// Cartoon face swishing mouthwash from cheek to cheek (kids mode).
struct MouthwashFaceAnimation: View {
    var color: Color
    private let palette = DrawPalette.forStyle(.kids)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 40)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let w = size.width, h = size.height
                let faceR = min(w, h) * 0.36
                let faceC = CGPoint(x: w / 2, y: h * 0.50)
                let slosh = CGFloat(sin(t * 2.6))

                let face = Path(ellipseIn: CGRect(x: faceC.x - faceR, y: faceC.y - faceR * 0.95, width: faceR * 2, height: faceR * 1.9))
                ctx.fill(face, with: .color(palette.skin))

                // Cheeks puff alternately.
                for side in [-1.0, 1.0] {
                    let amount = max(0, CGFloat(side) * slosh)
                    let cheekR = faceR * (0.30 + 0.22 * amount)
                    let cheekC = CGPoint(x: faceC.x + CGFloat(side) * faceR * (0.78 + 0.12 * amount), y: faceC.y + faceR * 0.22)
                    ctx.fill(Path(ellipseIn: CGRect(x: cheekC.x - cheekR, y: cheekC.y - cheekR, width: cheekR * 2, height: cheekR * 2)), with: .color(palette.skin))
                    let blushR = cheekR * 0.45
                    ctx.fill(Path(ellipseIn: CGRect(x: cheekC.x - blushR, y: cheekC.y - blushR * 0.6, width: blushR * 2, height: blushR * 1.2)), with: .color(palette.gum.opacity(0.35 + 0.35 * Double(amount))))
                }

                // Happy squeezed eyes.
                for side in [-1.0, 1.0] {
                    let ex = faceC.x + CGFloat(side) * faceR * 0.36
                    let ey = faceC.y - faceR * 0.28
                    var eye = Path()
                    eye.move(to: CGPoint(x: ex - 9, y: ey + 3))
                    eye.addQuadCurve(to: CGPoint(x: ex + 9, y: ey + 3), control: CGPoint(x: ex, y: ey - 9))
                    ctx.stroke(eye, with: .color(Color(red: 0.25, green: 0.2, blue: 0.3)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                // See-through mouth with sloshing liquid.
                let mouthRect = CGRect(x: faceC.x - faceR * 0.62, y: faceC.y + faceR * 0.12, width: faceR * 1.24, height: faceR * 0.52)
                let mouth = Path(roundedRect: mouthRect, cornerRadius: mouthRect.height / 2)
                ctx.fill(mouth, with: .color(palette.mouthInterior))
                var liquidCtx = ctx
                liquidCtx.clip(to: mouth)
                var liquid = Path()
                let baseY = mouthRect.midY + mouthRect.height * 0.05
                let tilt = slosh * mouthRect.height * 0.35
                liquid.move(to: CGPoint(x: mouthRect.minX - 10, y: baseY + tilt))
                let stepsN = 24
                for s in 0...stepsN {
                    let fx = CGFloat(s) / CGFloat(stepsN)
                    let x = mouthRect.minX - 10 + (mouthRect.width + 20) * fx
                    let y = baseY + tilt - 2 * tilt * fx + sin(fx * .pi * 3 + CGFloat(t) * 7) * 3
                    liquid.addLine(to: CGPoint(x: x, y: y))
                }
                liquid.addLine(to: CGPoint(x: mouthRect.maxX + 10, y: mouthRect.maxY + 10))
                liquid.addLine(to: CGPoint(x: mouthRect.minX - 10, y: mouthRect.maxY + 10))
                liquid.closeSubpath()
                liquidCtx.fill(liquid, with: .color(color.opacity(0.85)))
                for k in 0..<8 {
                    let seed = Draw.hash(k * 13 + 5)
                    let life = CGFloat((t * 0.9 + Double(seed)).truncatingRemainder(dividingBy: 1))
                    let x = mouthRect.minX + mouthRect.width * (0.1 + seed * 0.8) + slosh * 12
                    let y = mouthRect.maxY - life * mouthRect.height * 0.9
                    let r = 1.5 + seed * 2.5
                    liquidCtx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(Double(0.7 - life * 0.5))))
                }
                ctx.stroke(mouth, with: .color(palette.gumDark), lineWidth: 3)

                // Swish arrow.
                let arrowY = faceC.y + faceR * 1.08
                let dir: CGFloat = slosh >= 0 ? 1 : -1
                let ax = faceC.x - dir * 30
                var arrow = Path()
                arrow.move(to: CGPoint(x: ax, y: arrowY))
                arrow.addLine(to: CGPoint(x: ax + dir * 60, y: arrowY))
                arrow.move(to: CGPoint(x: ax + dir * 50, y: arrowY - 7))
                arrow.addLine(to: CGPoint(x: ax + dir * 60, y: arrowY))
                arrow.addLine(to: CGPoint(x: ax + dir * 50, y: arrowY + 7))
                ctx.stroke(arrow, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Little bottle in the corner.
                var bctx = ctx
                bctx.translateBy(x: w * 0.10, y: h * 0.62)
                bctx.rotate(by: .radians(-0.18 + 0.05 * sin(t * 2.6)))
                bctx.fill(Path(roundedRect: CGRect(x: -12, y: -26, width: 24, height: 44), cornerRadius: 6), with: .color(color.opacity(0.9)))
                bctx.fill(Path(roundedRect: CGRect(x: -6, y: -36, width: 12, height: 12), cornerRadius: 3), with: .color(color.opacity(0.7)))
                bctx.fill(Path(roundedRect: CGRect(x: -8, y: -12, width: 16, height: 18), cornerRadius: 3), with: .color(.white.opacity(0.85)))
            }
        }
        .accessibilityLabel("Animation of a face swishing mouthwash from cheek to cheek")
    }
}
