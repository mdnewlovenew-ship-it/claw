import SwiftUI

struct SensorsView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        List {
            Section("Sensor Snapshot") {
                row("Timestamp", app.currentSnapshot.timestamp.formatted())
                row("Motion", app.currentSnapshot.motionState.displayName)
                row("Steps", optionalNumber(app.currentSnapshot.steps))
                row("Distance (m)", optionalNumber(app.currentSnapshot.distance))
                row("Cadence", optionalNumber(app.currentSnapshot.cadence))
                row("Battery", app.currentSnapshot.batteryLevel >= 0
                    ? "\(Int((app.currentSnapshot.batteryLevel * 100).rounded()))%"
                    : "—")
                row("Charging", app.currentSnapshot.charging ? "Yes" : "No")
                row("Heart Rate", optionalNumber(app.currentSnapshot.heartRate, suffix: " bpm"))
                row("Blood Glucose", optionalNumber(app.currentSnapshot.bloodGlucose, suffix: " mg/dL"))
                row("Active Energy", optionalNumber(app.currentSnapshot.activeEnergy, suffix: " kcal"))
                row("Voice Level", String(format: "%.3f", app.currentSnapshot.voiceLevel))
                row("Recording", app.currentSnapshot.isRecording ? "Yes" : "No")
                row("HealthKit Available", app.currentSnapshot.healthKitAvailable ? "Yes" : "No")
                row("Location Available", app.currentSnapshot.locationAvailable ? "Yes" : "No")
            }

            if let location = app.currentSnapshot.location {
                Section("Location") {
                    row("Latitude", String(format: "%.6f", location.latitude))
                    row("Longitude", String(format: "%.6f", location.longitude))
                    row("Accuracy", String(format: "%.1f m", location.accuracy))
                    row("Timestamp", location.timestamp.formatted())
                }
            }

            Section {
                Button("Rebuild Snapshot") {
                    app.rebuildSnapshot()
                }
            }
        }
        .navigationTitle("Sensors")
        .onAppear { app.rebuildSnapshot() }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func optionalNumber(_ value: Double?, suffix: String = "") -> String {
        guard let value else { return "—" }
        return String(format: "%.2f%@", value, suffix)
    }
}
