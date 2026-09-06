import SwiftUI

struct VoiceView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Voice stays on this iPhone. Nothing is uploaded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    WaveformView(levels: appState.audio.levels, isLive: appState.audio.isRecording)
                        .frame(height: 140)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )

                    MetricCardGrid {
                        MetricCard(
                            title: "Duration",
                            value: formatDuration(appState.audio.metrics.duration),
                            systemImage: "timer"
                        )
                        MetricCard(
                            title: "Avg Level",
                            value: String(format: "%.0f%%", appState.audio.metrics.averageLevel * 100),
                            systemImage: "waveform"
                        )
                        MetricCard(
                            title: "Peak",
                            value: String(format: "%.0f%%", appState.audio.metrics.peakLevel * 100),
                            systemImage: "chart.bar.fill"
                        )
                        MetricCard(
                            title: "RMS / Amplitude",
                            value: String(format: "%.3f", appState.audio.metrics.averageLevel),
                            subtitle: "Normalized estimate"
                        )
                    }

                    HStack(spacing: 12) {
                        Button {
                            appState.startVoiceRecording()
                        } label: {
                            Label("Start Recording", systemImage: "record.circle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(appState.audio.isRecording || appState.permissions.statuses[.microphone] != .authorized)

                        Button {
                            appState.stopVoiceRecording()
                        } label: {
                            Label("Stop Recording", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!appState.audio.isRecording)
                    }

                    if appState.permissions.statuses[.microphone] != .authorized {
                        Text("Grant Microphone access in Permissions before recording.")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if let error = appState.audio.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !appState.audio.recordings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Local Recordings")
                                .font(.headline)
                            ForEach(appState.audio.recordings.prefix(10), id: \.self) { url in
                                Text(url.lastPathComponent)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Voice")
        }
    }

    private func formatDuration(_ value: TimeInterval) -> String {
        let total = Int(value)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

struct WaveformView: View {
    let levels: [Float]
    let isLive: Bool

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width / CGFloat(max(levels.count, 1))
            HStack(alignment: .center, spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isLive ? Color.cyan : Color.secondary.opacity(0.45))
                        .frame(width: max(2, width - 2), height: max(4, CGFloat(level) * geo.size.height))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .animation(.easeOut(duration: 0.08), value: levels)
    }
}
