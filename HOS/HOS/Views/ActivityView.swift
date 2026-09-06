import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: appState.motion.motionState.systemImage)
                            .font(.system(size: 42))
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.motion.motionState.displayName)
                                .font(.largeTitle.bold())
                            Text(appState.motion.isMonitoring ? "Live Core Motion" : "Not monitoring")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        LiveDot(color: appState.motion.isMonitoring ? .green : .secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    MetricCardGrid {
                        MetricCard(
                            title: "Steps",
                            value: appState.motion.steps.map { "\(Int($0))" } ?? "—",
                            subtitle: "Pedometer today",
                            systemImage: "shoeprints.fill"
                        )
                        MetricCard(
                            title: "Distance",
                            value: appState.motion.distance.map { String(format: "%.0f m", $0) } ?? "—",
                            systemImage: "point.bottomleft.forward.to.point.topright.scurvepath"
                        )
                        MetricCard(
                            title: "Cadence",
                            value: appState.motion.cadence.map { String(format: "%.1f sps", $0) } ?? "—",
                            subtitle: CMCadenceAvailabilityText,
                            systemImage: "metronome.fill"
                        )
                        MetricCard(
                            title: "Confidence",
                            value: appState.motion.confidence.capitalized,
                            subtitle: appState.motion.lastUpdate.map { "Updated \($0.formatted(date: .omitted, time: .standard))" } ?? "No update",
                            systemImage: "checkmark.seal"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected states")
                            .font(.headline)
                        ForEach(MotionState.allCases, id: \.self) { state in
                            HStack {
                                Image(systemName: state.systemImage)
                                Text(state.displayName)
                                Spacer()
                                if state == appState.motion.motionState {
                                    Text("Live")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.cyan)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    if let error = appState.motion.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if !appState.motion.isMonitoring {
                        Text("Enable Motion & Fitness in Permissions to start live activity updates.")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Button {
                        appState.motion.start()
                        appState.storage.append(
                            eventType: "Motion monitoring",
                            value: "Restarted",
                            source: "CoreMotion"
                        )
                    } label: {
                        Label("Start / Restart Monitoring", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Activity")
        }
    }

    private var CMCadenceAvailabilityText: String {
        "If supported by device"
    }
}
