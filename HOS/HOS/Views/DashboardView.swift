import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var app: AppState
    @State private var now = Date()

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(
                            title: "Battery",
                            value: app.battery.percentageText,
                            subtitle: app.battery.stateText,
                            systemImage: app.battery.isCharging ? "battery.100.bolt" : "battery.100"
                        )
                        MetricCard(
                            title: "Movement",
                            value: app.motion.motionState.displayName,
                            subtitle: app.motion.isMonitoring ? "Live" : "Idle",
                            systemImage: app.motion.motionState.systemImage
                        )
                        MetricCard(
                            title: "Microphone",
                            value: app.audio.isRecording ? "Recording" : "Idle",
                            subtitle: app.audio.isRecording
                                ? String(format: "%.0fs · lvl %.2f", app.audio.metrics.duration, app.audio.metrics.averageLevel)
                                : "Not recording",
                            systemImage: "mic.fill"
                        )
                        MetricCard(
                            title: "Location",
                            value: app.location.isAuthorized ? "Available" : "Off",
                            subtitle: app.location.snapshot.map { String(format: "±%.0fm", $0.accuracy) } ?? "When In Use only",
                            systemImage: "location.fill"
                        )
                        MetricCard(
                            title: "HealthKit",
                            value: app.healthKit.isAvailable ? (app.healthKit.isAuthorized ? "Ready" : "Available") : "N/A",
                            subtitle: app.healthKit.lastUpdated.map { "Updated \($0.formatted(date: .omitted, time: .shortened))" } ?? "Not refreshed",
                            systemImage: "heart.fill"
                        )
                        MetricCard(
                            title: "Heart Rate",
                            value: app.healthKit.snapshot.heartRate.map { "\(Int($0.rounded())) bpm" } ?? "—",
                            subtitle: app.healthKit.snapshot.heartRateDate.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Needs Health permission",
                            systemImage: "waveform.path.ecg"
                        )
                        MetricCard(
                            title: "Steps",
                            value: stepText,
                            subtitle: "Today",
                            systemImage: "figure.walk"
                        )
                        MetricCard(
                            title: "Distance",
                            value: distanceText,
                            subtitle: "Walking + running",
                            systemImage: "map"
                        )
                        MetricCard(
                            title: "Active Energy",
                            value: app.healthKit.snapshot.activeEnergyKilocalories.map { String(format: "%.0f kcal", $0) } ?? "—",
                            subtitle: "Today",
                            systemImage: "flame.fill"
                        )
                        MetricCard(
                            title: "Context",
                            value: app.lastContextMessage,
                            subtitle: "Latest local event",
                            systemImage: "sparkles"
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HOS")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SensorsView()
                    } label: {
                        Image(systemName: "sensor.tag.radiowaves.forward")
                    }
                }
            }
            .onReceive(clock) { now = $0 }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(now.formatted(date: .complete, time: .standard))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text("Personal health context — local only")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var stepText: String {
        if let steps = app.motion.steps ?? app.healthKit.snapshot.stepCount {
            return "\(Int(steps.rounded()))"
        }
        return "—"
    }

    private var distanceText: String {
        let meters = app.motion.distanceMeters ?? app.healthKit.snapshot.walkingRunningDistanceMeters
        guard let meters else { return "—" }
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }
}
