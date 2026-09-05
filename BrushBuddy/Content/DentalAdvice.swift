import Foundation

// MARK: - Sources
//
// Every piece of advice in the app is tagged with one or more of the source
// keys below. Citations are deliberately kept out of the UI.
//
// [NHS-clean]   NHS, "How to keep your teeth clean" (Live Well: Healthy teeth and gums).
//               https://www.nhs.uk/live-well/healthy-teeth-and-gums/how-to-keep-your-teeth-clean/
//               Two minutes twice a day with fluoride toothpaste; spit, don't rinse; clean
//               between teeth daily with interdental brushes or floss; don't use mouthwash
//               straight after brushing, use it at a different time such as after lunch;
//               don't eat or drink for 30 minutes after a fluoride mouthwash; small-headed
//               brush with soft to medium bristles.
// [NHS-fluor]   NHS, "Fluoride". https://www.nhs.uk/conditions/fluoride/
//               Adults should use toothpaste containing 1,350–1,500 ppm fluoride.
// [NHS-gum]     NHS, "Gum disease". https://www.nhs.uk/conditions/gum-disease/
//               Bleeding gums are a sign of gum inflammation; see a dentist if it persists.
// [ADA-brush]   American Dental Association, MouthHealthy, "Brushing Your Teeth".
//               https://www.mouthhealthy.org/all-topics-a-z/brushing-your-teeth
//               45° to the gums; gentle short strokes; outer, inner then chewing surfaces;
//               tilt the brush vertically for the inside of the front teeth; brush the
//               tongue to remove bacteria; two minutes twice a day.
// [ADA-floss]   American Dental Association, MouthHealthy, "Flossing".
//               https://www.mouthhealthy.org/all-topics-a-z/flossing
//               About 18 inches of floss wound around the middle fingers; guide it with a
//               gentle rubbing motion; never snap it into the gums; curve it into a "C"
//               against one tooth and rub gently up and down; use a fresh section per tooth;
//               water flossers are an option for people with braces, bridges or implants.
// [ADA-tbrush]  American Dental Association, MouthHealthy, "Toothbrushes".
//               https://www.mouthhealthy.org/all-topics-a-z/toothbrushes
//               Soft-bristled brush; replace every 3–4 months or when bristles fray.
// [ADA-care]    American Dental Association, "Statement on Toothbrush Care: Cleaning,
//               Storage and Replacement" (Oral Health Topics).
//               https://www.ada.org/resources/ada-library/oral-health-topics/toothbrushes
//               Don't share brushes; rinse after use; store upright and let air-dry; don't
//               routinely cover brushes or store them in closed containers; keep brushes in
//               the same holder from touching; replace every 3–4 months or sooner if frayed.
//               Notes there is no clinical evidence that brushes cause reinfection after
//               illness, so that advice is precautionary only.
// [ADA-rinse]   American Dental Association, MouthHealthy, "Mouthwash (Mouthrinse)".
//               https://www.mouthhealthy.org/all-topics-a-z/mouthwash
//               Therapeutic rinses can reduce plaque, gingivitis and decay (fluoride);
//               follow the label directions; not a substitute for brushing and cleaning
//               between teeth; not for children under 6 (swallowing risk); alcohol-containing
//               rinses can cause a burning sensation.
// [OHF-care]    Oral Health Foundation, "Caring for my teeth and gums".
//               https://www.dentalhealth.org/caring-for-my-teeth
//               Tilt bristles to 45° at the gumline and use small circular movements on
//               every surface; with an electric brush, hold the head against each tooth
//               and let it do the work; small-headed brush with soft to medium bristles.
// [OHF-erosion] Oral Health Foundation, "Dental erosion". https://www.dentalhealth.org/dental-erosion
//               Wait at least an hour after eating or drinking anything acidic before brushing.
// [Cochrane]    Worthington HV, MacDonald L, Poklepovic Pericic T, et al. "Home use of
//               interdental cleaning devices, in addition to toothbrushing, for preventing
//               and controlling periodontal diseases and dental caries." Cochrane Database
//               Syst Rev 2019;4:CD012018. https://doi.org/10.1002/14651858.CD012018.pub2
//               Interdental brushes and oral irrigators (water flossers) reduce gingivitis
//               versus brushing alone (low-certainty); interdental brushes may beat floss;
//               little evidence that oral irrigation reduces plaque.
// [Mazhari]     Mazhari F, Boskabady M, Moeintaghavi A, Habibi A. "The effect of
//               toothbrushing and flossing sequence on interdental plaque reduction and
//               fluoride retention: A randomized controlled clinical trial." J Periodontol
//               2018;89(7):824–832. https://doi.org/10.1002/JPER.17-0149
//               Flossing before brushing reduced interdental plaque more and left more
//               fluoride between the teeth than brushing first.
// [Wiegand]     Wiegand A, Schlueter N. "The role of oral hygiene: does toothbrushing harm?"
//               Monogr Oral Sci 2014;25:215–219. https://doi.org/10.1159/000360379
//               Excessive brushing force and abrasive pastes contribute to tooth wear and
//               gum recession.
// [Waterpik]    Water Flosser manufacturer instructions (Waterpik, "How to use a Water
//               Flosser"). https://www.waterpik.com/oral-health/how-to/
//               Manufacturer guidance, not clinical evidence: lean over the sink, lips
//               loosely closed around the tip; lowest pressure first; lukewarm water; tip
//               at 90° to the gumline; pause briefly between teeth; start with back teeth.

/// All of the guidance shown in the app, in one place so it is easy to review.
/// General advice only — never a substitute for what a person's own dentist says.
enum DentalAdvice {

    static func tips(for stage: BrushingStage) -> [Tip] {
        switch stage {
        case .waterPick: return waterPick
        case .floss: return floss
        case .brush: return brush
        case .mouthwash: return mouthwash
        }
    }

    static let waterPick: [Tip] = [
        // [Cochrane] gingivitis reduction with oral irrigators; [ADA-floss] braces/bridges/implants.
        Tip(kind: .why, text: "A water flosser flushes food and soft plaque from between teeth and just under the gumline, and has been shown to reduce gum inflammation. It's especially handy around braces, bridges and implants."),
        // [Waterpik]
        Tip(kind: .how, text: "Lean over the sink and close your lips loosely around the tip so the water runs out into the basin instead of spraying."),
        // [Waterpik]
        Tip(kind: .how, text: "Hold the tip at a 90° angle to your gumline. Follow the line of the gums and pause for a second or two between each tooth."),
        // [Waterpik]
        Tip(kind: .how, text: "Start on the lowest pressure setting with lukewarm water. Turn it up only if it stays comfortable."),
        // [Waterpik]
        Tip(kind: .how, text: "Start with the back teeth — they're the easiest to forget."),
        // [Cochrane] little evidence oral irrigation reduces plaque; interdental brushes/floss do.
        Tip(kind: .warning, text: "A water flosser is a great extra, but there's little evidence it removes plaque the way floss or interdental brushes do. Use it alongside them, not instead."),
    ]

    static let floss: [Tip] = [
        // [NHS-clean] clean between teeth daily; [ADA-floss] brush can't reach between teeth.
        Tip(kind: .why, text: "A toothbrush can't reach the surfaces between your teeth. Cleaning there every day helps prevent gum disease and the decay that starts between teeth."),
        // [Mazhari]
        Tip(kind: .why, text: "Cleaning between your teeth before you brush removes more plaque and leaves more fluoride from your toothpaste between the teeth."),
        // [ADA-floss]
        Tip(kind: .how, text: "Use about 45 cm (18 in) of floss. Wind most around one middle finger and the rest around the other, so you can unwind a clean section for each tooth."),
        // [ADA-floss]
        Tip(kind: .how, text: "Guide the floss between the teeth with a gentle rubbing motion. Never snap it down into the gum."),
        // [ADA-floss]
        Tip(kind: .how, text: "Curve it into a C-shape against one tooth and rub gently up and down, dipping just under the gumline. Then do the same on the neighbouring tooth."),
        // [NHS-clean] brushes or floss; [Cochrane] interdental brushes may be more effective than floss.
        Tip(kind: .how, text: "Interdental brushes work at least as well as floss and may be better where gaps are wider. Use whichever you'll actually do every day."),
        // [NHS-gum]
        Tip(kind: .warning, text: "Bleeding when you clean between your teeth is a sign of gum inflammation. It usually settles as your gums get healthier — if it keeps happening, see your dentist."),
    ]

    static let brush: [Tip] = [
        // [NHS-clean] [ADA-brush] two minutes, twice a day. The 30-second quarters are our arithmetic.
        Tip(kind: .why, text: "Two minutes, twice a day — 30 seconds for each quarter of your mouth — removes plaque before it can harden and feed the bacteria that cause decay and gum disease."),
        // [NHS-fluor]
        Tip(kind: .how, text: "Use a fluoride toothpaste — for adults, one with 1,350 to 1,500 ppm fluoride."),
        // [OHF-care] 45° and small circles; [Wiegand] force and wear.
        Tip(kind: .how, text: "Angle the bristles at 45° to the gumline and use small, gentle circular movements. Brushing harder doesn't clean better — it wears enamel and gums."),
        // [ADA-brush]
        Tip(kind: .how, text: "In each quarter, clean the outer surfaces, then the inner surfaces, then the chewing surfaces."),
        // [ADA-brush]
        Tip(kind: .how, text: "For the inside of the front teeth, tilt the brush upright and use gentle up-and-down strokes."),
        // [OHF-care]
        Tip(kind: .how, text: "Using an electric brush? Let it do the work: hold the head against each tooth for a few seconds and move slowly from tooth to tooth. No scrubbing."),
        // [ADA-tbrush] soft bristles; [NHS-clean] [OHF-care] small head.
        Tip(kind: .how, text: "Choose a soft-bristled brush with a small head so you can reach the back teeth."),
        // [ADA-brush]
        Tip(kind: .how, text: "Finish by brushing your tongue from back to front — it removes bacteria and keeps your breath fresh."),
        // [NHS-clean]
        Tip(kind: .warning, text: "When you're done, spit — don't rinse. Rinsing with water washes away the fluoride that keeps protecting your teeth."),
        // [OHF-erosion]
        Tip(kind: .warning, text: "Wait about an hour after eating or drinking anything acidic before brushing. Acid softens enamel, and brushing it straight away wears it down."),
    ]

    static let mouthwash: [Tip] = [
        // [NHS-clean] fluoride mouthwash helps prevent decay; [ADA-rinse] therapeutic rinses for gingivitis.
        Tip(kind: .why, text: "A fluoride mouthwash reaches every surface in your mouth and tops up the protection against decay. Antibacterial rinses can also help with gum health if your dentist suggests one."),
        // [ADA-rinse] follow the label; 20 ml for 30 s is the typical label instruction.
        Tip(kind: .how, text: "Follow the label — typically about 20 ml (four teaspoons) swished for 30 seconds — making sure it reaches the back and between your teeth."),
        // [NHS-clean] fluoride; [ADA-rinse] alcohol can cause a burning sensation.
        Tip(kind: .how, text: "Choose a mouthwash with fluoride. Alcohol-free versions avoid the burning and dryness some people get."),
        // [NHS-clean]
        Tip(kind: .how, text: "Don't eat or drink for 30 minutes afterwards so the fluoride has time to work."),
        // [NHS-clean]
        Tip(kind: .warning, text: "Best practice: use mouthwash at a different time from brushing — after lunch, say — because rinsing straight after brushing washes away the concentrated fluoride from your toothpaste. If you use it now, make sure it contains fluoride."),
        // [ADA-rinse]
        Tip(kind: .warning, text: "Mouthwash is an extra, not a replacement for brushing and cleaning between your teeth. Spit it out — never swallow. Not for children under six unless a dentist advises it."),
    ]

    static let toothbrushCare: [Tip] = [
        // [ADA-care] [ADA-tbrush]. The app's 90-day counter is the conservative end of 3–4 months.
        Tip(kind: .how, text: "Replace your toothbrush — or electric brush head — every three to four months. Worn bristles clean far less effectively."),
        // [ADA-care] [ADA-tbrush]
        Tip(kind: .how, text: "Replace it sooner if the bristles look frayed, matted or splayed outwards. If they no longer stand straight, it's time."),
        // [ADA-care] rinse, store upright, air-dry, don't cover.
        Tip(kind: .how, text: "Rinse the brush well after use and store it upright, uncovered, so it can air-dry. Damp, covered bristles grow bacteria."),
        // [ADA-care] don't share; keep brushes in one holder from touching.
        Tip(kind: .how, text: "Never share a brush, and keep brushes stored together from touching each other."),
        // Precautionary only: [ADA-care] notes there is no clinical evidence that brushes cause reinfection.
        Tip(kind: .how, text: "Many dentists also suggest a fresh brush after you've been ill. There's no firm evidence either way, but it's a cheap precaution."),
    ]

    static func recommendationWhenDisabled(for stage: BrushingStage) -> String {
        switch stage {
        case .waterPick:
            // [Cochrane] [ADA-floss]
            return "Water flossing is optional if you floss or use interdental brushes, but it's a helpful extra for gum health — especially with braces, bridges or implants."
        case .floss:
            // [NHS-clean]
            return "Dentists recommend cleaning between your teeth every day. If you skip it in one slot, make sure it's on in the other."
        case .brush:
            // [NHS-clean] [ADA-brush]
            return "Brushing twice a day for two minutes with fluoride toothpaste is the single most important thing you can do for your teeth. We strongly recommend keeping this on."
        case .mouthwash:
            // [NHS-clean]
            return "A fluoride mouthwash is a useful extra. Ideally use it at a separate time from brushing so you don't rinse away your toothpaste's fluoride."
        }
    }

    // [Mazhari] floss-then-brush; [NHS-clean] two minutes, spit don't rinse, mouthwash at a separate time.
    static let routineOrderExplanation = "Clean between your teeth first (water flosser, then floss) so the fluoride in your toothpaste can reach more of each tooth. Brush for two full minutes, brush your tongue, then spit without rinsing. Mouthwash works best at a separate time of day, but if you use it now, pick one with fluoride."

    static let disclaimer = "BrushBuddy offers general oral-health guidance based on public advice from dental bodies. It is not a substitute for advice from your own dentist or hygienist."
}
