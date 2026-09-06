import SwiftUI

struct VoiceView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    waveform

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(
                            title: "Duration",
                            value: String(format: "%.1fs", app.audio.metrics.duration),
                            systemImage: "timer"
                        )
                        MetricCard(
                            title: "Avg Level",
                            value: String(format: "%.3f", app.audio.metrics.averageLevel),
                            systemImage: "waveform"
                        )
                        MetricCard(
                            title: "Peak",
                            value: String(format: "%.3f", app.audio.metrics.peakLevel),
                            systemImage: "chart.bar.fill"
                        )
                        MetricCard(
                            title: "RMS / Amplitude",
                            value: String(format: "%.3f", app.audio.metrics.averageLevel),
                            subtitle: "Normalized estimate",
                            systemImage: "tuningfork"
                        )
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                if app.permissions.status(for: .microphone) != .authorized {
                                    await app.requestPermission(.microphone)
                                }
                                if app.permissions.status(for: .microphone) == .authorized {
                                    app.audio.startRecording()
                                }
                            }
                        } label: {
                            Text("START RECORDING")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(app.audio.isRecording)

                        Button {
                            app.audio.stopRecording()
                        } label: {
                            Text("STOP RECORDING")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!app.audio.isRecording)
                    }

                    if let error = app.audio.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local recordings")
                            .font(.headline)
                        Text("Stored only in the app Documents folder. Never uploaded.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if app.audio.recordings.isEmpty {
                            Text("No recordings yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(app.audio.recordings, id: \.self) { url in
                                Text(url.lastPathComponent)
                                    .font(.subheadline.monospaced())
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Voice")
        }
    }

    private var waveform: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(app.audio.waveform.enumerated()), id: \.offset) { _, level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(app.audio.isRecording ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(height: max(4, CGFloat(level) * 120))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .animation(.easeOut(duration: 0.08), value: app.audio.waveform)
    }
}
