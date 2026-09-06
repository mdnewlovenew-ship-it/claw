import SwiftUI

struct HealthView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Health metrics are informational context only. HOS is not a medical diagnostic system.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !appState.healthKit.isAvailable {
                        Text("HealthKit is unavailable on this device.")
                            .foregroundStyle(.orange)
                    } else if !appState.healthKit.authorizationRequested {
                        Text("Request HealthKit access from Permissions to load metrics.")
                            .foregroundStyle(.orange)
                    }

                    let health = appState.healthKit.snapshot

                    MetricCardGrid {
                        metric("Steps", health.stepCount.map { "\(Int($0))" }, health.stepCountDate, "shoeprints.fill")
                        metric("Distance", health.walkingRunningDistance.map { String(format: "%.0f m", $0) }, health.walkingRunningDistanceDate, "figure.walk")
                        metric("Active Energy", health.activeEnergy.map { String(format: "%.0f kcal", $0) }, health.activeEnergyDate, "flame.fill")
                        metric("Heart Rate", health.heartRate.map { "\(Int($0)) bpm" }, health.heartRateDate, "heart.fill")
                        metric("Resting HR", health.restingHeartRate.map { "\(Int($0)) bpm" }, health.restingHeartRateDate, "heart")
                        metric("Walking HR Avg", health.walkingHeartRateAverage.map { "\(Int($0)) bpm" }, health.walkingHeartRateAverageDate, "figure.walk.motion")
                        metric("Blood Glucose", health.bloodGlucose.map { String(format: "%.1f mg/dL", $0) }, health.bloodGlucoseDate, "drop.fill")
                        metric("Body Mass", health.bodyMass.map { String(format: "%.1f kg", $0) }, health.bodyMassDate, "scalemass.fill")
                        metric("Sleep", health.sleepHours.map { String(format: "%.1f h", $0) }, health.sleepDate, "bed.double.fill")
                        metric("SpO₂", health.oxygenSaturation.map { String(format: "%.0f%%", $0) }, health.oxygenSaturationDate, "lungs.fill")
                    }

                    if let error = appState.healthKit.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await appState.refreshHealthData(source: "Health tab") }
                    } label: {
                        Label("Refresh Health Data", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(!appState.healthKit.isAvailable)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Health")
        }
    }

    private func metric(_ title: String, _ value: String?, _ date: Date?, _ image: String) -> MetricCard {
        MetricCard(
            title: title,
            value: value ?? "—",
            subtitle: date.map { "Last: \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "No data",
            systemImage: image
        )
    }
}
