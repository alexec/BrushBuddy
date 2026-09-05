import SwiftUI

/// Shared geometry helpers for the front-on mouth used by the water-flosser
/// and floss animations. Everything is drawn in a Canvas from a `rect`.
enum FrontMouth {
    static let teethPerRow = 10

    struct Layout {
        let rect: CGRect
        var upperGum: CGRect { CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.14) }
        var lowerGum: CGRect { CGRect(x: rect.minX, y: rect.maxY - rect.height * 0.14, width: rect.width, height: rect.height * 0.14) }
        var interior: CGRect { CGRect(x: rect.minX, y: rect.minY + rect.height * 0.40, width: rect.width, height: rect.height * 0.20) }

        /// Frame for tooth `index` (0 = screen-left) in the upper or lower row.
        func tooth(_ index: Int, upper: Bool) -> CGRect {
            let slot = rect.width / CGFloat(FrontMouth.teethPerRow)
            let w = slot * 0.84
            // Front teeth are a touch taller than the back ones.
            let distFromCentre = abs(CGFloat(index) + 0.5 - CGFloat(FrontMouth.teethPerRow) / 2) / (CGFloat(FrontMouth.teethPerRow) / 2)
            let h = rect.height * (0.31 - 0.07 * distFromCentre)
            let x = rect.minX + slot * CGFloat(index) + (slot - w) / 2
            if upper {
                return CGRect(x: x, y: upperGum.maxY - rect.height * 0.03, width: w, height: h)
            } else {
                return CGRect(x: x, y: lowerGum.minY + rect.height * 0.03 - h, width: w, height: h)
            }
        }

        /// X position of the gap between tooth `index` and `index + 1`.
        func gapX(_ index: Int) -> CGFloat {
            let slot = rect.width / CGFloat(FrontMouth.teethPerRow)
            return rect.minX + slot * CGFloat(index + 1)
        }

        /// Y of the gumline for a row (where tooth meets gum).
        func gumlineY(upper: Bool) -> CGFloat {
            upper ? upperGum.maxY : lowerGum.minY
        }
    }

    /// Whether a tooth belongs to the highlighted zone. Screen-right is the user's right.
    static func isHighlighted(index: Int, upper: Bool, zone: MouthZone) -> Bool {
        let right = index >= teethPerRow / 2
        switch zone {
        case .upper: return upper
        case .lower: return !upper
        case .upperRight: return upper && right
        case .upperLeft: return upper && !right
        case .lowerRight: return !upper && right
        case .lowerLeft: return !upper && !right
        case .whole: return true
        case .tongue: return false
        }
    }

    /// Indices of gaps inside a zone (between two highlighted teeth).
    static func gapIndices(for zone: MouthZone) -> [Int] {
        let upper = zone.isUpper
        return (0..<(teethPerRow - 1)).filter { isHighlighted(index: $0, upper: upper, zone: zone) && isHighlighted(index: $0 + 1, upper: upper, zone: zone) }
    }

    static func draw(in context: inout GraphicsContext, layout: Layout, zone: MouthZone, glow: Color, palette: DrawPalette) {
        let rect = layout.rect
        if palette.detailed {
            // Lips around the mouth.
            let lips = Path(roundedRect: rect.insetBy(dx: -rect.width * 0.04, dy: -rect.height * 0.06), cornerRadius: rect.height * 0.35)
            context.fill(lips, with: .color(palette.gumDark))
        }
        // Mouth interior.
        context.fill(Path(roundedRect: rect, cornerRadius: rect.height * 0.30), with: .color(palette.mouthInterior))

        // Gums.
        var gums = Path()
        gums.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: layout.upperGum.height + rect.height * 0.04), cornerSize: CGSize(width: rect.height * 0.3, height: rect.height * 0.3))
        gums.addRoundedRect(in: CGRect(x: rect.minX, y: layout.lowerGum.minY - rect.height * 0.04, width: rect.width, height: layout.lowerGum.height + rect.height * 0.04), cornerSize: CGSize(width: rect.height * 0.3, height: rect.height * 0.3))
        context.clip(to: Path(roundedRect: rect, cornerRadius: rect.height * 0.30))
        context.fill(gums, with: .color(palette.gum))

        // Teeth.
        for upper in [true, false] {
            for i in 0..<teethPerRow {
                let frame = layout.tooth(i, upper: upper)
                let highlighted = isHighlighted(index: i, upper: upper, zone: zone)
                let radius = frame.width * 0.32
                var tooth = Path()
                if upper {
                    tooth.addPath(Path(roundedRect: frame, cornerSize: CGSize(width: radius, height: radius)))
                } else {
                    tooth.addPath(Path(roundedRect: frame, cornerSize: CGSize(width: radius, height: radius)))
                }
                if highlighted {
                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: glow.opacity(0.7), radius: frame.width * 0.35))
                        layer.fill(tooth, with: .color(palette.tooth))
                    }
                } else {
                    context.fill(tooth, with: .color(palette.toothDim))
                }
                if palette.detailed {
                    context.stroke(tooth, with: .color(Color.black.opacity(0.10)), lineWidth: 1)
                }
            }
        }
    }
}

/// Top-down arch view for brushing: upper arch on top, lower arch below.
enum ArchMouth {
    static let teethPerArch = 12

    struct Layout {
        let rect: CGRect
        var upperCentre: CGPoint { CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.36) }
        var lowerCentre: CGPoint { CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.36) }
        var radiusX: CGFloat { rect.width * 0.38 }
        var radiusY: CGFloat { rect.height * 0.30 }
        var toothSize: CGSize { CGSize(width: rect.width * 0.075, height: rect.width * 0.075) }

        /// Position and outward angle (radians) of tooth `index` on an arch.
        /// Index 0 is screen-left back molar; last is screen-right back molar.
        func tooth(_ index: Int, upper: Bool) -> (centre: CGPoint, angle: CGFloat) {
            let n = ArchMouth.teethPerArch
            let fraction = (CGFloat(index) + 0.5) / CGFloat(n)
            // Upper arch spans 180°→360° (an arc over the top); lower is mirrored.
            let angle: CGFloat = upper ? (.pi + fraction * .pi) : (.pi - fraction * .pi)
            let c = upper ? upperCentre : lowerCentre
            let pt = CGPoint(x: c.x + cos(angle) * radiusX, y: c.y + sin(angle) * radiusY)
            return (pt, angle)
        }

        var tongueRect: CGRect {
            CGRect(x: lowerCentre.x - radiusX * 0.55, y: lowerCentre.y - radiusY * 0.75, width: radiusX * 1.1, height: radiusY * 1.55)
        }
    }

    static func isHighlighted(index: Int, upper: Bool, zone: MouthZone) -> Bool {
        let right = index >= teethPerArch / 2
        switch zone {
        case .upper: return upper
        case .lower: return !upper
        case .upperRight: return upper && right
        case .upperLeft: return upper && !right
        case .lowerRight: return !upper && right
        case .lowerLeft: return !upper && !right
        case .whole: return true
        case .tongue: return false
        }
    }

    static func highlightedTeeth(zone: MouthZone, layout: Layout) -> [CGPoint] {
        var pts: [CGPoint] = []
        for upper in [true, false] {
            for i in 0..<teethPerArch where isHighlighted(index: i, upper: upper, zone: zone) {
                pts.append(layout.tooth(i, upper: upper).centre)
            }
        }
        return pts
    }

    static func draw(in context: inout GraphicsContext, layout: Layout, zone: MouthZone, glow: Color, palette: DrawPalette) {
        // Soft gum arches behind the teeth.
        for upper in [true, false] {
            let c = upper ? layout.upperCentre : layout.lowerCentre
            var arch = Path()
            let rx = layout.radiusX + layout.toothSize.width * 0.75
            let ry = layout.radiusY + layout.toothSize.height * 0.75
            let start: CGFloat = upper ? .pi : 0
            let end: CGFloat = upper ? 2 * .pi : .pi
            arch.move(to: CGPoint(x: c.x + cos(start) * rx, y: c.y + sin(start) * ry))
            let steps = 40
            for s in 1...steps {
                let a = start + (end - start) * CGFloat(s) / CGFloat(steps)
                arch.addLine(to: CGPoint(x: c.x + cos(a) * rx, y: c.y + sin(a) * ry))
            }
            let irx = layout.radiusX - layout.toothSize.width * 0.75
            let iry = layout.radiusY - layout.toothSize.height * 0.75
            for s in 0...steps {
                let a = end - (end - start) * CGFloat(s) / CGFloat(steps)
                arch.addLine(to: CGPoint(x: c.x + cos(a) * irx, y: c.y + sin(a) * iry))
            }
            arch.closeSubpath()
            context.fill(arch, with: .color(palette.gum))
        }

        // Tongue sits inside the lower arch.
        let tongue = Path(ellipseIn: layout.tongueRect)
        let tongueActive = zone == .tongue
        if tongueActive {
            context.drawLayer { layer in
                layer.addFilter(.shadow(color: glow.opacity(0.8), radius: 12))
                layer.fill(tongue, with: .color(palette.detailed ? palette.tongue : palette.tongue.opacity(0.9)))
            }
        } else {
            context.fill(tongue, with: .color(palette.detailed ? palette.tongue.opacity(0.6) : palette.tongue))
        }
        if palette.detailed {
            var midline = Path()
            midline.move(to: CGPoint(x: layout.tongueRect.midX, y: layout.tongueRect.minY + layout.tongueRect.height * 0.15))
            midline.addLine(to: CGPoint(x: layout.tongueRect.midX, y: layout.tongueRect.maxY - layout.tongueRect.height * 0.25))
            context.stroke(midline, with: .color(palette.gumDark.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // Teeth.
        for upper in [true, false] {
            for i in 0..<teethPerArch {
                let (centre, _) = layout.tooth(i, upper: upper)
                let size = layout.toothSize
                let frame = CGRect(x: centre.x - size.width / 2, y: centre.y - size.height / 2, width: size.width, height: size.height)
                let tooth = Path(roundedRect: frame, cornerRadius: size.width * 0.3)
                let highlighted = isHighlighted(index: i, upper: upper, zone: zone)
                if highlighted {
                    context.drawLayer { layer in
                        layer.addFilter(.shadow(color: glow.opacity(0.75), radius: size.width * 0.4))
                        layer.fill(tooth, with: .color(palette.tooth))
                    }
                } else {
                    context.fill(tooth, with: .color(palette.toothDim))
                }
                if palette.detailed {
                    context.stroke(tooth, with: .color(.black.opacity(0.10)), lineWidth: 1)
                    if i < 3 || i >= teethPerArch - 3 {
                        var fissure = Path()
                        fissure.move(to: CGPoint(x: frame.minX + frame.width * 0.3, y: frame.midY))
                        fissure.addLine(to: CGPoint(x: frame.maxX - frame.width * 0.3, y: frame.midY))
                        context.stroke(fissure, with: .color(.black.opacity(0.12)), lineWidth: 1)
                    }
                }
            }
        }
    }
}

/// Small drawing helpers shared by the animations.
enum Draw {
    static func toothbrush(in context: inout GraphicsContext, head: CGPoint, handleDirection: CGVector, headSize: CGSize, color: Color, rotation: CGFloat = 0) {
        // Handle: a capsule from the head outward.
        let handleLength = headSize.height * 2.6
        let end = CGPoint(x: head.x + handleDirection.dx * handleLength, y: head.y + handleDirection.dy * handleLength)
        var handle = Path()
        handle.move(to: head)
        handle.addLine(to: end)
        context.stroke(handle, with: .color(color), style: StrokeStyle(lineWidth: headSize.width * 0.55, lineCap: .round))
        context.stroke(handle, with: .color(.white.opacity(0.35)), style: StrokeStyle(lineWidth: headSize.width * 0.18, lineCap: .round))

        // Head: rounded rect aligned with the handle direction.
        let angle = atan2(handleDirection.dy, handleDirection.dx) + .pi / 2 + rotation
        var headCtx = context
        headCtx.translateBy(x: head.x, y: head.y)
        headCtx.rotate(by: .radians(angle))
        let headRect = CGRect(x: -headSize.width / 2, y: -headSize.height / 2, width: headSize.width, height: headSize.height)
        headCtx.fill(Path(roundedRect: headRect, cornerRadius: headSize.width * 0.4), with: .color(color))
        // Bristles.
        let bristleRect = headRect.insetBy(dx: headSize.width * 0.18, dy: headSize.height * 0.12)
        headCtx.fill(Path(roundedRect: bristleRect, cornerRadius: headSize.width * 0.2), with: .color(.white))
        let rows = 4, cols = 2
        for r in 0..<rows {
            for c in 0..<cols {
                let x = bristleRect.minX + bristleRect.width * (CGFloat(c) + 0.5) / CGFloat(cols)
                let y = bristleRect.minY + bristleRect.height * (CGFloat(r) + 0.5) / CGFloat(rows)
                headCtx.fill(Path(ellipseIn: CGRect(x: x - 1.2, y: y - 1.2, width: 2.4, height: 2.4)), with: .color(color.opacity(0.35)))
            }
        }
    }

    static func sparkle(in context: inout GraphicsContext, at p: CGPoint, size: CGFloat, color: Color, opacity: Double) {
        guard opacity > 0.01 else { return }
        var star = Path()
        star.move(to: CGPoint(x: p.x, y: p.y - size))
        star.addQuadCurve(to: CGPoint(x: p.x + size, y: p.y), control: p)
        star.addQuadCurve(to: CGPoint(x: p.x, y: p.y + size), control: p)
        star.addQuadCurve(to: CGPoint(x: p.x - size, y: p.y), control: p)
        star.addQuadCurve(to: CGPoint(x: p.x, y: p.y - size), control: p)
        context.fill(star, with: .color(color.opacity(opacity)))
    }

    /// 0→1 smooth step.
    static func smooth(_ x: CGFloat) -> CGFloat {
        let c = min(1, max(0, x))
        return c * c * (3 - 2 * c)
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint { CGPoint(x: lerp(a.x, b.x, t), y: lerp(a.y, b.y, t)) }

    /// Deterministic pseudo-random in 0..<1 for a seed.
    static func hash(_ seed: Int) -> CGFloat {
        var x = UInt64(bitPattern: Int64(seed)) &* 0x9E3779B97F4A7C15
        x ^= x >> 29
        x = x &* 0xBF58476D1CE4E5B9
        x ^= x >> 32
        return CGFloat(x % 10_000) / 10_000
    }
}
