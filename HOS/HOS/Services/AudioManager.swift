import Foundation
import AVFoundation

@MainActor
final class AudioManager: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var metrics = VoiceMetrics.empty
    @Published private(set) var waveform: [Float] = Array(repeating: 0, count: 40)
    @Published private(set) var lastError: String?
    @Published private(set) var recordings: [URL] = []
    @Published private(set) var lastUpdated: Date?

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var startedAt: Date?
    private var peak: Float = 0
    private var sumLevels: Float = 0
    private var sampleCount: Int = 0

    private var recordingsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Recordings", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    init() {
        refreshRecordingList()
    }

    func startRecording() {
        guard !isRecording else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)

            let filename = "hos-\(Int(Date().timeIntervalSince1970)).m4a"
            let url = recordingsDirectory.appendingPathComponent(filename)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.prepareToRecord(), recorder.record() else {
                lastError = "Unable to start microphone recording."
                return
            }

            audioRecorder = recorder
            isRecording = true
            startedAt = Date()
            peak = 0
            sumLevels = 0
            sampleCount = 0
            lastError = nil
            lastUpdated = Date()
            startMetering()
            refreshRecordingList()
        } catch {
            lastError = error.localizedDescription
            isRecording = false
        }
    }

    func stopRecording() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        metrics.isRecording = false
        lastUpdated = Date()
        refreshRecordingList()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func refreshRecordingList() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        recordings = files
            .filter { $0.pathExtension.lowercased() == "m4a" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private func startMetering() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMeters()
            }
        }
    }

    private func updateMeters() {
        guard let recorder = audioRecorder, let startedAt else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let peakPower = recorder.peakPower(forChannel: 0)
        let normalized = max(0, min(1, (power + 60) / 60))
        let normalizedPeak = max(0, min(1, (peakPower + 60) / 60))

        peak = max(peak, normalizedPeak)
        sumLevels += normalized
        sampleCount += 1

        var nextWave = waveform
        nextWave.removeFirst()
        nextWave.append(normalized)
        waveform = nextWave

        metrics = VoiceMetrics(
            averageLevel: sampleCount > 0 ? sumLevels / Float(sampleCount) : 0,
            peakLevel: peak,
            duration: Date().timeIntervalSince(startedAt),
            timestamp: Date(),
            isRecording: true
        )
        lastUpdated = Date()
    }
}
