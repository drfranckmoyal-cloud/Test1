import AVFoundation
import Foundation
import Speech
import SwiftUI

/// Comment l'apprenant prend la parole.
enum VoiceMode: String, CaseIterable, Identifiable {
    /// Le micro reste ouvert ; parler coupe le tuteur.
    case handsFree
    /// On appuie pour parler, on relâche pour envoyer.
    case pushToTalk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .handsFree: return "Mains libres"
        case .pushToTalk: return "Appui pour parler"
        }
    }

    var systemImage: String {
        switch self {
        case .handsFree: return "waveform"
        case .pushToTalk: return "mic.circle"
        }
    }
}

/// Ce que le micro et la voix font en ce moment.
enum VoiceActivity: Equatable {
    case idle
    case speaking
    case listening
    /// Le réseau est tombé : la séance se met en pause proprement.
    case paused
}

/// La voix de l'app : elle parle, elle écoute, et elle se tait dès que
/// l'apprenant ouvre la bouche.
///
/// L'interruption est le point dur. En mains libres, le micro tourne pendant
/// que le tuteur parle ; au premier son assez fort, la synthèse s'arrête net —
/// pas à la fin de la phrase, tout de suite (A09).
@MainActor
final class VoiceService: NSObject, ObservableObject {

    @Published private(set) var activity: VoiceActivity = .idle
    @Published var mode: VoiceMode = .handsFree {
        didSet { modeDidChange(from: oldValue) }
    }
    /// Ce que l'apprenant est en train de dire, mis à jour au fil de l'eau.
    @Published private(set) var transcript: String = ""
    /// La confiance de la reconnaissance sur le dernier segment, quand iOS la
    /// donne. Affichée en mode développeur.
    @Published private(set) var lastConfidence: Float?
    /// Vrai quand l'apprenant a coupé le tuteur.
    @Published private(set) var didBargeIn = false
    @Published private(set) var permissionDenied = false
    /// Le niveau sonore d'entrée, pour l'onde à l'écran.
    @Published private(set) var inputLevel: Float = 0

    /// Appelée quand un tour de parole est terminé.
    var onUtterance: ((String, Float?) -> Void)?
    /// Appelée quand le tuteur a fini de parler sans être coupé.
    var onSpeechFinished: (() -> Void)?

    private let synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Au-dessus de ce niveau, on considère que quelqu'un parle vraiment.
    private let bargeInThreshold: Float = 0.055
    /// Le temps de silence qui clôt un tour de parole en mains libres.
    private let silenceToEndTurn: TimeInterval = 1.4
    private var lastVoiceAt: Date?
    private var silenceTimer: Timer?

    override init() {
        super.init()
        synthesizer.delegate = self
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    }

    // MARK: - Autorisations

    /// Demande micro et reconnaissance vocale. À appeler une fois, au début.
    func requestPermissions() async {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let microphone = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        permissionDenied = !(speech && microphone)
    }

    // MARK: - Parler

    /// Fait parler le tuteur. En mains libres, le micro reste ouvert pendant
    /// qu'il parle : c'est ce qui permet de le couper.
    func speak(_ text: String, tutor: Tutor, language: String = "zh-CN") {
        guard !text.isEmpty else { return }
        didBargeIn = false
        configureSession(forRecording: mode == .handsFree)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = tutor.speechRate
        utterance.voice = voice(for: tutor, language: language)
        utterance.postUtteranceDelay = 0.1

        activity = .speaking
        synthesizer.speak(utterance)

        if mode == .handsFree {
            startListening(endsOnSilence: false)
        }
    }

    /// Coupe la parole du tuteur sur-le-champ.
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func voice(for tutor: Tutor, language: String) -> AVSpeechSynthesisVoice? {
        if let identifier = tutor.preferredVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            return voice
        }
        // À défaut, la meilleure voix disponible pour la langue demandée.
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(String(language.prefix(2))) }
        if let premium = candidates.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = candidates.first(where: { $0.quality == .enhanced }) { return enhanced }
        return candidates.first ?? AVSpeechSynthesisVoice(language: language)
    }

    // MARK: - Écouter

    /// Ouvre le micro. En appui pour parler, le tour se termine au relâchement ;
    /// en mains libres, après un silence.
    func startListening(endsOnSilence: Bool = true) {
        guard !permissionDenied else { return }
        guard let recognizer, recognizer.isAvailable else { return }
        if audioEngine.isRunning { return }

        configureSession(forRecording: true)
        transcript = ""
        lastConfidence = nil
        lastVoiceAt = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // La reconnaissance sur l'appareil évite d'envoyer la voix au réseau et
        // tient quand la connexion est mauvaise.
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            request.append(buffer)
            let level = Self.level(of: buffer)
            Task { @MainActor in self?.handleInput(level: level) }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopListening()
            return
        }

        if activity != .speaking { activity = .listening }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    self.lastConfidence = result.bestTranscription.segments.last?.confidence
                    if result.isFinal { self.finishTurn() }
                }
                if error != nil { self.stopListening() }
            }
        }

        if endsOnSilence { startSilenceWatch() }
    }

    /// Ferme le micro et rend le tour de parole.
    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        inputLevel = 0
        if activity == .listening { activity = .idle }
    }

    /// Le doigt vient de se poser sur le bouton parler.
    func beginPushToTalk() {
        stopSpeaking()
        startListening(endsOnSilence: false)
    }

    /// Le doigt vient de se lever : on envoie ce qui a été dit.
    func endPushToTalk() {
        finishTurn()
    }

    // MARK: - Interruption

    private func handleInput(level: Float) {
        inputLevel = level
        guard level > bargeInThreshold else { return }
        lastVoiceAt = Date()

        // L'apprenant parle pendant que le tuteur parle : on coupe, et c'est à
        // lui. Rien n'attend la fin de la phrase.
        if activity == .speaking, mode == .handsFree {
            didBargeIn = true
            stopSpeaking()
            activity = .listening
            startSilenceWatch()
        }
    }

    private func startSilenceWatch() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let last = self.lastVoiceAt else { return }
                if Date().timeIntervalSince(last) > self.silenceToEndTurn {
                    self.finishTurn()
                }
            }
        }
    }

    private func finishTurn() {
        let said = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let confidence = lastConfidence
        stopListening()
        guard !said.isEmpty else { return }
        transcript = ""
        onUtterance?(said, confidence)
    }

    // MARK: - Session audio

    private func configureSession(forRecording recording: Bool) {
        let session = AVAudioSession.sharedInstance()
        do {
            if recording {
                try session.setCategory(
                    .playAndRecord,
                    mode: .spokenAudio,
                    options: [.duckOthers, .defaultToSpeaker, .allowBluetooth]
                )
            } else {
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            }
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Un échec de configuration audio ne doit pas faire tomber la séance.
        }
    }

    /// Le mode change en pleine séance sans rien perdre : on ferme ce qui est
    /// ouvert, on rouvre selon le nouveau mode (A10).
    private func modeDidChange(from previous: VoiceMode) {
        guard previous != mode else { return }
        stopListening()
        if mode == .handsFree, activity == .speaking {
            startListening(endsOnSilence: false)
        }
    }

    /// Met la voix en pause quand le réseau tombe.
    func pause() {
        stopSpeaking()
        stopListening()
        activity = .paused
    }

    func resume() {
        if activity == .paused { activity = .idle }
    }

    /// Niveau sonore moyen d'un tampon, entre 0 et 1.
    private static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        var sum: Float = 0
        for index in 0..<count {
            let sample = channel[index]
            sum += sample * sample
        }
        return (sum / Float(count)).squareRoot()
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            guard !self.didBargeIn else { return }
            if self.activity == .speaking { self.activity = .idle }
            self.onSpeechFinished?()
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            if self.activity == .speaking { self.activity = .listening }
        }
    }
}
