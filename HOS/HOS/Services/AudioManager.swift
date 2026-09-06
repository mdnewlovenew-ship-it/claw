import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    @Published private(set) var metrics = VoiceMetrics.empty
    @Published private(set) var isRecording = false
    @Published private(set) var levels: [Float] = Array(repeating: 0, count: 40)
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdate: Date?
    @Published private(set) var recordings: [URL] = []

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var startedAt: Date?
    private var peak: Float = 0
    private var sum: Float = 0
    private var samples: Int = 0

    private var recordingsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("HOSRecordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        refreshRecordingList()
    }

    func startRecording() {
        guard !isRecording else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try session.setActive(true)

            let filename = "hos-\(Int(Date().timeIntervalSince1970)).m4a"
            let url = recordingsDirectory.appendingPathComponent(filename)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            self.recorder = recorder
            startedAt = Date()
            peak = 0
            sum = 0
            samples = 0
            isRecording = true
            lastError = nil
            metrics = VoiceMetrics(
                averageLevel: 0,
                peakLevel: 0,
                duration: 0,
                timestamp: Date(),
                isRecording: true,
                recordingURL: url
            )
            startMetering()
        } catch {
            lastError = error.localizedDescription
            isRecording = false
        }
    }

    func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        let url = recorder?.url
        recorder = nil
        isRecording = false

        let duration = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        let average = samples > 0 ? sum / Float(samples) : 0
        metrics = VoiceMetrics(
            averageLevel: average,
            peakLevel: peak,
            duration: duration,
            timestamp: Date(),
            isRecording: false,
            recordingURL: url
        )
        lastUpdate = Date()
        startedAt = nil
        refreshRecordingList()

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }

    private func updateMeters() {
        guard let recorder, isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        let normalized = max(0, min(1, (power + 60) / 60))
        let normalizedPeak = max(0, min(1, (peakPower + 60) / 60))

        peak = max(peak, normalizedPeak)
        sum += normalized
        samples += 1

        var next = levels
        next.removeFirst()
        next.append(normalized)
        levels = next

        let duration = startedAt.map { Date().timeIntervalSince($0) } ?? 0
        metrics = VoiceMetrics(
            averageLevel: samples > 0 ? sum / Float(samples) : 0,
            peakLevel: peak,
            duration: duration,
            timestamp: Date(),
            isRecording: true,
            recordingURL: recorder.url
        )
        lastUpdate = Date()
    }

    private func refreshRecordingList() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        recordings = files
            .filter { $0.pathExtension.lowercased() == "m4a" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}
