import SwiftUI

/// A region of the mouth that a step of the routine focuses on.
/// Left/right are the user's own left/right as seen in a mirror,
/// so the user's right side is drawn on the right of the screen.
enum MouthZone: Hashable {
    case upper
    case lower
    case upperRight
    case upperLeft
    case lowerLeft
    case lowerRight
    case tongue
    case whole

    var isUpper: Bool {
        switch self {
        case .upper, .upperRight, .upperLeft: return true
        default: return false
        }
    }

    var isRight: Bool? {
        switch self {
        case .upperRight, .lowerRight: return true
        case .upperLeft, .lowerLeft: return false
        default: return nil
        }
    }
}

/// One timed step inside a stage (for example "Upper right, 30 seconds").
struct StageStep: Identifiable, Hashable {
    let id: String
    let title: String
    let instruction: String
    let duration: TimeInterval
    let zone: MouthZone
}

/// A piece of dental-hygiene advice shown while a stage is running.
struct Tip: Identifiable, Hashable {
    enum Kind: Hashable { case why, how, warning }
    let id = UUID()
    let kind: Kind
    let text: String

    var label: String {
        switch kind {
        case .why: return "Why it matters"
        case .how: return "How to do it well"
        case .warning: return "Watch out"
        }
    }

    var symbol: String {
        switch kind {
        case .why: return "lightbulb.fill"
        case .how: return "hand.thumbsup.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

/// The four stages of a full oral-hygiene routine, in the recommended order.
enum BrushingStage: String, CaseIterable, Codable, Identifiable, Comparable {
    case waterPick
    case floss
    case brush
    case mouthwash

    var id: String { rawValue }

    /// Recommended order: clean between teeth first so fluoride from toothpaste
    /// can reach more tooth surfaces, then brush, then rinse.
    static var recommendedOrder: [BrushingStage] { allCases }

    static func < (lhs: BrushingStage, rhs: BrushingStage) -> Bool {
        guard let l = allCases.firstIndex(of: lhs), let r = allCases.firstIndex(of: rhs) else { return false }
        return l < r
    }

    var title: String {
        switch self {
        case .waterPick: return "Water Flosser"
        case .floss: return "Floss"
        case .brush: return "Brush"
        case .mouthwash: return "Mouthwash"
        }
    }

    /// Fits in tight spaces such as the four-up start card.
    var shortTitle: String {
        switch self {
        case .waterPick: return "Water Pick"
        default: return title
        }
    }

    var subtitle: String {
        switch self {
        case .waterPick: return "Flush out what hides between your teeth"
        case .floss: return "Clean the sides your brush can't reach"
        case .brush: return "Two minutes, every surface, gently"
        case .mouthwash: return "A final fluoride rinse"
        }
    }

    var symbol: String {
        switch self {
        case .waterPick: return "drop.fill"
        case .floss: return "line.diagonal"
        case .brush: return "sparkles"
        case .mouthwash: return "mouth.fill"
        }
    }

    var color: Color {
        switch self {
        case .waterPick: return Color(red: 0.40, green: 0.76, blue: 1.0)
        case .floss: return Color(red: 0.74, green: 0.62, blue: 1.0)
        case .brush: return Color(red: 0.38, green: 0.90, blue: 0.70)
        case .mouthwash: return Color(red: 0.36, green: 0.86, blue: 0.92)
        }
    }

    /// Timed stages count down and celebrate when they finish. Untimed stages
    /// take as long as they take; the user taps Next when done.
    var isTimed: Bool {
        switch self {
        case .waterPick, .floss: return false
        case .brush, .mouthwash: return true
        }
    }

    /// Step instructions repeat advice from DentalAdvice; see the source keys
    /// in that file. Water flosser: [Waterpik]. Floss: [ADA-floss]. Brush 45° and
    /// circles: [OHF-care]; surfaces, upright for front teeth, tongue: [ADA-brush];
    /// spit don't rinse: [NHS-clean]. Mouthwash: [ADA-rinse] [NHS-clean].
    var steps: [StageStep] {
        switch self {
        case .waterPick:
            return [
                StageStep(id: "wp-all", title: "Along the gumline", instruction: "Start at the back. Trace the upper gumline, pausing between teeth, then the lower. Tip at 90° to the gums; let the water drain into the sink.", duration: 0, zone: .whole),
            ]
        case .floss:
            return [
                StageStep(id: "fl-all", title: "Every gap", instruction: "Work around all four quarters. Slide gently between each pair of teeth, curve into a C, and move up and down just under the gumline. Fresh section for each tooth.", duration: 0, zone: .whole),
            ]
        case .brush:
            return [
                StageStep(id: "br-ur", title: "Upper right", instruction: "Bristles at 45° to the gumline. Small, gentle circles: outside, inside, then chewing surfaces.", duration: 30, zone: .upperRight),
                StageStep(id: "br-ul", title: "Upper left", instruction: "Move to the upper left. Same gentle circles — pressure doesn't clean, technique does.", duration: 30, zone: .upperLeft),
                StageStep(id: "br-ll", title: "Lower left", instruction: "Lower left. Tip the brush upright to reach behind the front teeth.", duration: 30, zone: .lowerLeft),
                StageStep(id: "br-lr", title: "Lower right", instruction: "Lower right. Get right to the back — the last molar is a cavity favourite.", duration: 30, zone: .lowerRight),
                StageStep(id: "br-tongue", title: "Tongue", instruction: "Brush your tongue gently from back to front to clear odour-causing bacteria. Then spit — don't rinse!", duration: 15, zone: .tongue),
            ]
        case .mouthwash:
            return [
                StageStep(id: "mw-swish", title: "Swish", instruction: "About 20 ml. Swish it around every part of your mouth for the full time, then spit. Don't swallow, and don't rinse with water afterwards.", duration: 30, zone: .whole),
            ]
        }
    }

    var totalDuration: TimeInterval { steps.reduce(0) { $0 + $1.duration } }

    var tips: [Tip] { DentalAdvice.tips(for: self) }

    /// Shown in Settings when a user turns a stage off. We respect the choice,
    /// but always keep recommending best practice.
    var recommendationWhenDisabled: String { DentalAdvice.recommendationWhenDisabled(for: self) }

    var completionCheer: String {
        switch self {
        case .waterPick: return "Flushed and fresh!"
        case .floss: return "Between-teeth champion!"
        case .brush: return "Sparkling clean!"
        case .mouthwash: return "Minty perfection!"
        }
    }
}
