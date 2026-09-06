import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let snap = appState.currentSnapshot

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sensor Snapshot")
                    .font(.title2.bold())
                Text("Combined view of the latest values from all available services.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                MetricCardGrid {
                    MetricCard(title: "Timestamp", value: snap.timestamp.formatted(date: .omitted, time: .standard))
                    MetricCard(title: "Motion", value: snap.motionState.displayName, systemImage: snap.motionState.systemImage)
                    MetricCard(title: "Steps", value: snap.steps.map { "\(Int($0))" } ?? "—")
                    MetricCard(title: "Distance", value: snap.distance.map { String(format: "%.0f m", $0) } ?? "—")
                    MetricCard(title: "Cadence", value: snap.cadence.map { String(format: "%.1f", $0) } ?? "—")
                    MetricCard(
                        title: "Battery",
                        value: snap.batteryLevel >= 0 ? "\(Int(snap.batteryLevel * 100))%" : "—",
                        subtitle: snap.charging ? "Charging" : "Not charging"
                    )
                    MetricCard(
                        title: "Location",
                        value: snap.location.map { String(format: "%.4f, %.4f", $0.latitude, $0.longitude) } ?? "—",
                        subtitle: snap.locationAvailable ? "Authorized" : "Not authorized"
                    )
                    MetricCard(title: "Heart Rate", value: snap.heartRate.map { "\(Int($0)) bpm" } ?? "—")
                    MetricCard(title: "Blood Glucose", value: snap.bloodGlucose.map { String(format: "%.1f", $0) } ?? "—")
                    MetricCard(title: "Active Energy", value: snap.activeEnergy.map { String(format: "%.0f kcal", $0) } ?? "—")
                    MetricCard(
                        title: "Voice Level",
                        value: String(format: "%.0f%%", snap.voiceLevel * 100),
                        subtitle: snap.isRecording ? "Recording" : "Idle"
                    )
                    MetricCard(
                        title: "HealthKit",
                        value: snap.healthKitAvailable ? "Available" : "Unavailable"
                    )
                }

                Button("Rebuild Snapshot") {
                    appState.rebuildSnapshot()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sensors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appState.rebuildSnapshot() }
    }
}
