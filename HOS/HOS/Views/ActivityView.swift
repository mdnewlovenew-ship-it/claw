import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(app.motion.motionState.displayName, systemImage: app.motion.motionState.systemImage)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        Text(app.motion.isMonitoring ? "Live Core Motion updates" : "Monitoring is off")
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Steps", value: app.motion.steps.map { "\(Int($0.rounded()))" } ?? "—", subtitle: "Today", systemImage: "shoeprints.fill")
                        MetricCard(title: "Distance", value: distanceText, subtitle: "Pedometer", systemImage: "lines.measurement.horizontal")
                        MetricCard(title: "Cadence", value: app.motion.cadence.map { String(format: "%.1f /s", $0) } ?? "—", subtitle: "If available", systemImage: "metronome.fill")
                        MetricCard(title: "Availability", value: app.motion.isAvailable ? "Yes" : "No", subtitle: app.motion.isAuthorized ? "Authorized" : "Needs permission", systemImage: "sensor.fill")
                    }

                    if let error = app.motion.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if let updated = app.motion.lastUpdated {
                        Text("Last motion update \(updated.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await app.requestPermission(.motion) }
                    } label: {
                        Text(app.motion.isMonitoring ? "Restart Motion Monitoring" : "Enable Motion & Fitness")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if app.location.isAuthorized {
                        locationBlock
                    } else {
                        Text("Location is optional. Enable it from Permissions if you want coordinates.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Permissions") { PermissionsView() }
                }
            }
        }
    }

    private var distanceText: String {
        guard let meters = app.motion.distanceMeters else { return "—" }
        return meters >= 1000 ? String(format: "%.2f km", meters / 1000) : String(format: "%.0f m", meters)
    }

    private var locationBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Location")
                .font(.headline)
            if let snap = app.location.snapshot {
                Text(String(format: "%.5f, %.5f", snap.latitude, snap.longitude))
                    .font(.body.monospacedDigit())
                Text(String(format: "Accuracy ±%.0f m · %@", snap.accuracy, snap.timestamp.formatted()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(app.location.lastError ?? "No fix yet")
                    .foregroundStyle(.secondary)
            }
            Button("Refresh Location Once") {
                app.location.refreshOnce()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}
