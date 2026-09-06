import SwiftUI

struct HealthView: View {
    @EnvironmentObject private var app: AppState
    @State private var refreshing = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("HOS is not a medical diagnostic system. Values are read-only HealthKit samples when available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Status") {
                    LabeledContent("HealthKit", value: app.healthKit.isAvailable ? "Available" : "Unavailable")
                    LabeledContent("Authorized", value: app.healthKit.isAuthorized ? "Yes" : "No")
                    if let updated = app.healthKit.lastUpdated {
                        LabeledContent("Last update", value: updated.formatted())
                    }
                    if let error = app.healthKit.lastError {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section("Metrics") {
                    metric("Steps", app.healthKit.snapshot.stepCount.map { "\(Int($0.rounded()))" }, app.healthKit.snapshot.stepCountDate)
                    metric("Distance", app.healthKit.snapshot.walkingRunningDistanceMeters.map { String(format: "%.0f m", $0) }, app.healthKit.snapshot.walkingRunningDistanceDate)
                    metric("Active Energy", app.healthKit.snapshot.activeEnergyKilocalories.map { String(format: "%.0f kcal", $0) }, app.healthKit.snapshot.activeEnergyDate)
                    metric("Heart Rate", app.healthKit.snapshot.heartRate.map { String(format: "%.0f bpm", $0) }, app.healthKit.snapshot.heartRateDate)
                    metric("Resting HR", app.healthKit.snapshot.restingHeartRate.map { String(format: "%.0f bpm", $0) }, app.healthKit.snapshot.restingHeartRateDate)
                    metric("Walking HR Avg", app.healthKit.snapshot.walkingHeartRateAverage.map { String(format: "%.0f bpm", $0) }, app.healthKit.snapshot.walkingHeartRateAverageDate)
                    metric("Blood Glucose", app.healthKit.snapshot.bloodGlucoseMgDl.map { String(format: "%.0f mg/dL", $0) }, app.healthKit.snapshot.bloodGlucoseDate)
                    metric("Body Mass", app.healthKit.snapshot.bodyMassKg.map { String(format: "%.1f kg", $0) }, app.healthKit.snapshot.bodyMassDate)
                    metric("Sleep", app.healthKit.snapshot.sleepHours.map { String(format: "%.1f h", $0) }, app.healthKit.snapshot.sleepDate)
                    metric("Oxygen Saturation", app.healthKit.snapshot.oxygenSaturation.map { String(format: "%.0f%%", $0) }, app.healthKit.snapshot.oxygenSaturationDate)
                }

                Section {
                    Button {
                        Task {
                            refreshing = true
                            if !app.healthKit.isAuthorized {
                                await app.requestPermission(.healthKit)
                            } else {
                                await app.healthKit.refresh()
                                app.record(type: "Health data refreshed", value: "Health data refreshed", source: "HealthKit")
                            }
                            refreshing = false
                        }
                    } label: {
                        HStack {
                            Text(app.healthKit.isAuthorized ? "Refresh Health Data" : "Request HealthKit Access")
                            if refreshing { Spacer(); ProgressView() }
                        }
                    }
                }
            }
            .navigationTitle("Health")
        }
    }

    @ViewBuilder
    private func metric(_ title: String, _ value: String?, _ date: Date?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value ?? "No data")
                    .foregroundStyle(.secondary)
            }
            if let date {
                Text("Last measured \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
