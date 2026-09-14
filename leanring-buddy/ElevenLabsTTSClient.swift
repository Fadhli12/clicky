//
//  ElevenLabsTTSClient.swift
//  leanring-buddy
//

import AVFoundation
import Foundation

@MainActor
final class ElevenLabsTTSClient: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var _isPlaying = false
    private var continuation: CheckedContinuation<Void, Never>?

    init(proxyURL: String) {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks `text` using macOS native speech synthesis.
    func speakText(_ text: String) async throws {
        try Task.checkCancellation()

        stopPlayback()

        let cleanText = text
            .replacingOccurrences(of: #"\*+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        utterance.pitchMultiplier = 1.0

        _isPlaying = true
        synthesizer.speak(utterance)
        print("🔊 Apple Native TTS: speaking (\(cleanText.prefix(40))...)")

        await withCheckedContinuation { cont in
            self.continuation = cont
        }
    }

    /// Whether TTS audio is currently playing back.
    var isPlaying: Bool {
        _isPlaying || synthesizer.isSpeaking
    }

    /// Stops any in-progress playback immediately.
    func stopPlayback() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        _isPlaying = false
        continuation?.resume()
        continuation = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self._isPlaying = false
            self.continuation?.resume()
            self.continuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self._isPlaying = false
            self.continuation?.resume()
            self.continuation = nil
        }
    }
}

