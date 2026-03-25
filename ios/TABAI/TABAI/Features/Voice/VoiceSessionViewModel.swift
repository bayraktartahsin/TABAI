import Foundation
import Combine
import AVFoundation
import Speech

@MainActor
final class VoiceSessionViewModel: ObservableObject {
    struct TranscriptLine: Identifiable, Equatable {
        let id: UUID
        let role: String
        let text: String
    }

    @Published private(set) var transcript: [TranscriptLine] = []
    @Published var isListening: Bool = false
    @Published private(set) var statusMessage: String = ""
    @Published private(set) var errorMessage: String?

    enum PermissionState: Equatable {
        case unknown
        case granted
        case denied
    }

    @Published private(set) var permissionState: PermissionState = .unknown

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    var canStartListening: Bool {
        permissionState != .denied
    }

    init() {
        refreshRecognizerLocale()
    }

    /// Recreate recognizer with current language setting
    func refreshRecognizerLocale() {
        let langCode = UserDefaults.standard.string(forKey: "tai.speechLanguage") ?? "en"
        // Map our language codes to proper BCP-47 locale identifiers
        let localeMap: [String: String] = [
            "system": Locale.current.identifier,
            "en": "en-US", "en-IN": "en-IN", "en-GB": "en-GB",
            "fr": "fr-FR", "fr-CA": "fr-CA",
            "de": "de-DE", "de-AT": "de-AT",
            "hi": "hi-IN", "it": "it-IT", "ja": "ja-JP", "ko": "ko-KR",
            "pt": "pt-PT", "pt-BR": "pt-BR",
            "ru": "ru-RU", "es": "es-ES", "es-419": "es-MX",
            "tr": "tr-TR", "uk": "uk-UA",
            "zh-Hans": "zh-CN", "th": "th-TH", "ar": "ar-SA",
        ]
        let resolvedLocale = localeMap[langCode] ?? langCode
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: resolvedLocale)) ?? SFSpeechRecognizer()
    }

    func clearDraft() {
        transcript = []
        statusMessage = ""
        errorMessage = nil
    }

    func startListening() async {
        guard !isListening else { return }
        errorMessage = nil

        // Request both mic and speech permissions
        let micGranted = await ensureMicrophonePermission()
        guard micGranted else {
            permissionState = .denied
            errorMessage = "Microphone access required. Enable in Settings."
            return
        }

        let speechGranted = await ensureSpeechPermission()
        guard speechGranted else {
            permissionState = .denied
            errorMessage = "Speech recognition access required. Enable in Settings."
            return
        }

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition unavailable for this language."
            return
        }

        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not start microphone."
            return
        }

        // Start recognition
        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    if !text.isEmpty {
                        let line = TranscriptLine(id: UUID(), role: "user", text: text)
                        // Replace the last partial with the latest
                        if self.transcript.isEmpty {
                            self.transcript.append(line)
                        } else {
                            self.transcript[self.transcript.count - 1] = line
                        }
                    }
                    if result.isFinal {
                        self.stopEngine()
                    }
                }
                if let error, self.isListening {
                    // Don't show error for user-initiated cancellation
                    if (error as NSError).code != 216 { // kAFAssistantErrorDomain cancelled
                        self.statusMessage = ""
                    }
                    self.stopEngine()
                }
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            errorMessage = "Could not start audio engine."
            return
        }

        self.audioEngine = engine
        self.recognitionRequest = request
        isListening = true
        permissionState = .granted
        statusMessage = "Listening..."
    }

    func stopListening() {
        recognitionRequest?.endAudio()
        stopEngine()
        statusMessage = ""
    }

    private func stopEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func ensureMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return true
            case .denied: return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { allowed in
                        continuation.resume(returning: allowed)
                    }
                }
            @unknown default: return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: return true
            case .denied: return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                        continuation.resume(returning: allowed)
                    }
                }
            @unknown default: return false
            }
        }
    }

    private func ensureSpeechPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { newStatus in
                    continuation.resume(returning: newStatus == .authorized)
                }
            }
        @unknown default: return false
        }
    }
}
