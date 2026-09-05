import AVFoundation

/// Plays short synthesised cues. Each cue has its own timbre so they are easy
/// to tell apart without looking: a soft pluck for steps, a bright bell
/// arpeggio for stages, and a brassy fanfare for the finished routine.
final class SoundPlayer {
    enum Sound: CaseIterable {
        case stepDone
        case stageDone
        case routineDone
    }

    static let shared = SoundPlayer()

    var isEnabled = true

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]
    private let sampleRate: Double = 44_100
    private var isConfigured = false

    private init() {}

    func play(_ sound: Sound) {
        guard isEnabled else { return }
        configureIfNeeded()
        guard isConfigured, let buffer = buffers[sound] else { return }
        if !engine.isRunning { try? engine.start() }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Mixing with other audio is a nicety; keep going without it.
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        for sound in Sound.allCases {
            buffers[sound] = render(notes: notes(for: sound), format: format)
        }
        do {
            try engine.start()
            isConfigured = true
        } catch {
            isConfigured = false
        }
    }

    // MARK: - Synthesis

    private enum Timbre {
        case pluck   // short, woody, marimba-like
        case bell    // clear sine with a little sparkle
        case brass   // rich harmonics, slower attack, sustained
    }

    private struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
        let volume: Double
        let timbre: Timbre
    }

    // Reference pitches: G4 392, C5 523.25, D5 587.33, E5 659.25, G5 783.99,
    // A5 880, C6 1046.5, D6 1174.66, E6 1318.5, G6 1568.
    private func notes(for sound: Sound) -> [Note] {
        switch sound {
        case .stepDone:
            // One soft "plip".
            return [
                Note(frequency: 1174.66, start: 0.00, duration: 0.16, volume: 0.55, timbre: .pluck),
                Note(frequency: 1567.98, start: 0.05, duration: 0.14, volume: 0.30, timbre: .pluck),
            ]
        case .stageDone:
            // Bright ascending bell arpeggio.
            return [
                Note(frequency: 523.25, start: 0.00, duration: 0.45, volume: 0.7, timbre: .bell),
                Note(frequency: 659.25, start: 0.12, duration: 0.45, volume: 0.7, timbre: .bell),
                Note(frequency: 783.99, start: 0.24, duration: 0.45, volume: 0.7, timbre: .bell),
                Note(frequency: 1046.5, start: 0.36, duration: 0.75, volume: 0.8, timbre: .bell),
            ]
        case .routineDone:
            // Ta-ta-ta-daa! brass fanfare, then a bell shimmer on top.
            return [
                Note(frequency: 392.00, start: 0.00, duration: 0.14, volume: 0.6, timbre: .brass),
                Note(frequency: 392.00, start: 0.17, duration: 0.14, volume: 0.6, timbre: .brass),
                Note(frequency: 392.00, start: 0.34, duration: 0.14, volume: 0.6, timbre: .brass),
                Note(frequency: 523.25, start: 0.52, duration: 1.10, volume: 0.6, timbre: .brass),
                Note(frequency: 659.25, start: 0.52, duration: 1.10, volume: 0.45, timbre: .brass),
                Note(frequency: 783.99, start: 0.52, duration: 1.10, volume: 0.40, timbre: .brass),
                Note(frequency: 1046.5, start: 0.80, duration: 0.6, volume: 0.35, timbre: .bell),
                Note(frequency: 1318.5, start: 0.90, duration: 0.6, volume: 0.35, timbre: .bell),
                Note(frequency: 1568.0, start: 1.00, duration: 0.7, volume: 0.35, timbre: .bell),
            ]
        }
    }

    private func sample(_ timbre: Timbre, phase p: Double, t: Double, progress: Double) -> Double {
        switch timbre {
        case .pluck:
            let attack = min(1, t / 0.002)
            let env = attack * exp(-progress * 5.5)
            let tone = sin(p) + 0.55 * sin(2 * p) + 0.25 * sin(3 * p) + 0.1 * sin(4.2 * p)
            return tone * env * 0.30
        case .bell:
            let attack = min(1, t / 0.008)
            let env = attack * pow(1 - progress, 1.6)
            let tone = sin(p) + 0.35 * sin(2 * p) + 0.12 * sin(3 * p)
            return tone * env * 0.25
        case .brass:
            let attack = min(1, t / 0.045)
            let release = progress < 0.7 ? 1 : (1 - progress) / 0.3
            let env = attack * release
            var tone = 0.0
            for n in 1...6 { tone += sin(Double(n) * p) / Double(n) }
            // Gentle vibrato for warmth.
            let vib = 1 + 0.004 * sin(2 * .pi * 5.5 * t)
            return tone * vib * env * 0.16
        }
    }

    private func render(notes: [Note], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let end = notes.map { $0.start + $0.duration }.max() ?? 0
        let frameCount = AVAudioFrameCount((end + 0.05) * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount
        for i in 0..<Int(frameCount) { channel[i] = 0 }

        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let noteFrames = Int(note.duration * sampleRate)
            for n in 0..<noteFrames {
                let idx = startFrame + n
                guard idx < Int(frameCount) else { break }
                let t = Double(n) / sampleRate
                let progress = Double(n) / Double(noteFrames)
                let phase = 2 * Double.pi * note.frequency * t
                channel[idx] += Float(sample(note.timbre, phase: phase, t: t, progress: progress) * note.volume)
            }
        }

        var peak: Float = 0
        for i in 0..<Int(frameCount) { peak = max(peak, abs(channel[i])) }
        if peak > 0.95 {
            let gain = 0.95 / peak
            for i in 0..<Int(frameCount) { channel[i] *= gain }
        }
        return buffer
    }
}
