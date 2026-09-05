import SwiftUI

/// Side-by-side brush heads: fresh bristles versus worn, splayed ones.
struct ToothbrushHeadIllustration: View {
    var body: some View {
        HStack(spacing: 28) {
            headView(worn: false, caption: "Good", tint: Theme.good)
            headView(worn: true, caption: "Replace", tint: Theme.warn)
        }
    }

    private func headView(worn: Bool, caption: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            Canvas { ctx, size in
                let headRect = CGRect(x: size.width * 0.30, y: size.height * 0.55, width: size.width * 0.40, height: size.height * 0.40)
                let handle = CGRect(x: size.width * 0.40, y: size.height * 0.85, width: size.width * 0.20, height: size.height * 0.25)
                ctx.fill(Path(roundedRect: handle, cornerRadius: 6), with: .color(Theme.accent))
                ctx.fill(Path(roundedRect: headRect, cornerRadius: 8), with: .color(Theme.accent))
                let tufts = 6
                for i in 0..<tufts {
                    let fx = (CGFloat(i) + 0.5) / CGFloat(tufts)
                    let baseX = headRect.minX + headRect.width * fx
                    let baseY = headRect.minY + 2
                    for k in 0..<3 {
                        let jitter = worn ? (Draw.hash(i * 7 + k * 3) - 0.5) : 0
                        let spread = worn ? (fx - 0.5) * 60 + jitter * 40 : 0
                        let length = worn ? size.height * (0.30 + Draw.hash(i + k * 11) * 0.12) : size.height * 0.42
                        let angle = spread * .pi / 180
                        let tip = CGPoint(x: baseX + sin(angle) * length + CGFloat(k - 1) * 2, y: baseY - cos(angle) * length)
                        var bristle = Path()
                        bristle.move(to: CGPoint(x: baseX + CGFloat(k - 1) * 2, y: baseY))
                        if worn {
                            bristle.addQuadCurve(to: tip, control: CGPoint(x: baseX + sin(angle) * length * 0.3 + CGFloat(k - 1) * 2, y: baseY - length * 0.6))
                        } else {
                            bristle.addLine(to: tip)
                        }
                        let bristleColor = worn ? Color(red: 0.93, green: 0.85, blue: 0.62) : Color.white
                        ctx.stroke(bristle, with: .color(bristleColor), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        ctx.stroke(bristle, with: .color(.black.opacity(0.12)), style: StrokeStyle(lineWidth: 0.6, lineCap: .round))
                    }
                }
            }
            .frame(width: 90, height: 110)
            Label(caption, systemImage: worn ? "xmark.circle.fill" : "checkmark.circle.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(tint)
        }
    }
}
