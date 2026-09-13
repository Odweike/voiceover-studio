import AVFoundation
import Combine
import Foundation

/// AVFoundation and metering are confined to the main actor; callbacks hop back explicitly.
@MainActor
final class AudioController: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @Published private(set) var recording = false
    @Published private(set) var playingID: UUID?
    @Published private(set) var level: Float = 0
    @Published private(set) var levelHistory = Array(repeating: Float(0.03), count: 52)
    @Published private(set) var recordingDuration: TimeInterval = 0
    var onRecordingError: ((String) -> Void)?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var playerID: UUID?
    private var timer: Timer?

    func start(at url: URL) throws {
        guard !recording else { throw StudioError(message: Strings.current.errAlreadyRecording) }
        stopPlayback()
        let recorder = try AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 24,
            AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false
        ])
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        guard recorder.record() else { throw StudioError(message: Strings.current.errMicNoStart) }
        self.recorder = recorder
        recording = true
        recordingDuration = 0
        levelHistory = Array(repeating: 0.03, count: 52)
        timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateMeter() }
        }
    }

    private func updateMeter() {
        guard let recorder, recording else { return }
        recorder.updateMeters()
        level = max(0.03, min(1, pow(10, recorder.averagePower(forChannel: 0) / 28)))
        recordingDuration = recorder.currentTime
        levelHistory.append(level)
        levelHistory.removeFirst(max(0, levelHistory.count - 52))
    }

    func stopRecording() {
        // Detach delegate before an intentional stop; late completion cannot affect a new take.
        recorder?.delegate = nil
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        recording = false
        level = 0
        recordingDuration = 0
    }

    func togglePlayback(_ take: Take, url: URL) throws {
        guard !recording else { throw StudioError(message: Strings.current.errFinishRecording) }
        if playerID == take.id, let player {
            if player.isPlaying { player.pause(); playingID = nil }
            else {
                guard player.play() else { throw StudioError(message: Strings.current.errPlayback) }
                playingID = take.id
            }
            return
        }
        stopPlayback()
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        guard player.play() else { throw StudioError(message: Strings.current.errPlayback) }
        self.player = player
        playerID = take.id
        playingID = take.id
    }

    func stopPlayback() {
        player?.delegate = nil
        player?.stop()
        player = nil
        playerID = nil
        playingID = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let identity = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == identity else { return }
            self.stopPlayback()
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        recordingFailed(recorder, message: flag ? Strings.current.errStoppedByDevice : Strings.current.errInterrupted)
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
        recordingFailed(recorder, message: error?.localizedDescription ?? Strings.current.errAudioEncode)
    }

    nonisolated private func recordingFailed(_ recorder: AVAudioRecorder, message: String) {
        let identity = ObjectIdentifier(recorder)
        Task { @MainActor [weak self] in
            guard let self, let current = self.recorder, ObjectIdentifier(current) == identity else { return }
            self.stopRecording()
            self.onRecordingError?(message)
        }
    }
}
