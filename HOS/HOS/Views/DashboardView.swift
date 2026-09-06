import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    MetricCardGrid {
                        MetricCard(
                            title: "Battery",
                            value: appState.battery.percentageText,
                            subtitle: appState.battery.stateLabel,
                            systemImage: appState.battery.isCharging ? "battery.100.bolt" : "battery.100"
                        )
                        MetricCard(
                            title: "Movement",
                            value: appState.motion.motionState.displayName,
                            subtitle: "Confidence: \(appState.motion.confidence)",
                            systemImage: appState.motion.motionState.systemImage
                        )
                        MetricCard(
                            title: "Microphone",
                            value: appState.audio.isRecording ? "Recording" : "Idle",
                            subtitle: appState.audio.isRecording
                                ? String(format: "%.0fs · level %.0f%%", appState.audio.metrics.duration, appState.audio.metrics.averageLevel * 100)
                                : "Local only",
                            systemImage: "mic.fill"
                        )
                        MetricCard(
                            title: "Location",
                            value: appState.location.isAuthorized ? "Available" : "Off",
                            subtitle: appState.location.isAuthorized
                                ? accuracyText
                                : "When In Use only",
                            systemImage: "location.fill"
                        )
                        MetricCard(
                            title: "HealthKit",
                            value: appState.healthKit.isAvailable ? (appState.healthKit.authorizationRequested ? "Ready" : "Available") : "Unavailable",
                            subtitle: appState.healthKit.lastUpdate.map { "Updated \(relative($0))" } ?? "Not refreshed",
                            systemImage: "heart.fill"
                        )
                        MetricCard(
                            title: "Heart Rate",
                            value: appState.healthKit.snapshot.heartRate.map { "\(Int($0.rounded())) bpm" } ?? "—",
                            subtitle: appState.healthKit.snapshot.heartRateDate.map { relative($0) } ?? "No data",
                            systemImage: "waveform.path.ecg"
                        )
                        MetricCard(
                            title: "Steps",
                            value: stepText,
                            subtitle: "Today",
                            systemImage: "shoeprints.fill"
                        )
                        MetricCard(
                            title: "Distance",
                            value: distanceText,
                            subtitle: "Walking / Running",
                            systemImage: "point.bottomleft.forward.to.point.topright.scurvepath"
                        )
                        MetricCard(
                            title: "Active Energy",
                            value: appState.healthKit.snapshot.activeEnergy.map { String(format: "%.0f kcal", $0) } ?? "—",
                            subtitle: appState.healthKit.snapshot.activeEnergyDate.map { relative($0) } ?? "No data",
                            systemImage: "flame.fill"
                        )
                        MetricCard(
                            title: "Context",
                            value: appState.lastContextMessage,
                            subtitle: relative(appState.currentSnapshot.timestamp),
                            systemImage: "sparkles"
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HOS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await appState.refreshAllData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(appState.isRefreshing)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timeFormatter.string(from: appState.now))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(dateFormatter.string(from: appState.now))
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Personal health context · local first")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var stepText: String {
        let steps = appState.motion.steps ?? appState.healthKit.snapshot.stepCount
        guard let steps else { return "—" }
        return "\(Int(steps.rounded()))"
    }

    private var distanceText: String {
        let meters = appState.motion.distance ?? appState.healthKit.snapshot.walkingRunningDistance
        guard let meters else { return "—" }
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    private var accuracyText: String {
        guard let accuracy = appState.location.accuracy else { return "Waiting…" }
        return String(format: "±%.0f m", accuracy)
    }

    private func relative(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
