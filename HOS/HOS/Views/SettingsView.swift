import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("HOS") {
                    NavigationLink("Permissions") { PermissionsView() }
                    NavigationLink("Sensors Snapshot") { SensorsView() }
                    NavigationLink("Camera") { CameraScreen() }
                    NavigationLink("Developer / Debug") { DebugPanelView() }
                }

                Section("Device") {
                    LabeledContent("Model", value: appState.device.modelName)
                    LabeledContent("System", value: "\(appState.device.systemName) \(appState.device.systemVersion)")
                    LabeledContent("Battery", value: "\(appState.battery.percentageText) · \(appState.battery.stateLabel)")
                }

                Section("Location (When In Use)") {
                    if let lat = appState.location.latitude,
                       let lon = appState.location.longitude {
                        LabeledContent("Latitude", value: String(format: "%.5f", lat))
                        LabeledContent("Longitude", value: String(format: "%.5f", lon))
                        LabeledContent("Accuracy", value: appState.location.accuracy.map { String(format: "±%.0f m", $0) } ?? "—")
                        LabeledContent(
                            "Timestamp",
                            value: appState.location.timestamp?.formatted(date: .abbreviated, time: .standard) ?? "—"
                        )
                    } else {
                        Text("No location yet. Authorize Location, then refresh.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Refresh Location Once") {
                        appState.location.refreshOnce()
                    }
                    .disabled(!appState.location.isAuthorized)
                }

                Section("Privacy") {
                    Text("All MVP data stays locally on the iPhone.")
                    Text("No cloud upload.")
                    Text("No advertising.")
                    Text("No analytics SDK.")
                    Text("No remote tracking.")
                    Text("You control every permission. HOS never auto-requests access on launch.")
                }
                .font(.subheadline)

                Section("Disclaimer") {
                    Text("HOS is a personal context prototype. It is not a medical device and does not provide diagnosis, treatment, or clinical advice.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct CameraScreen: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Text("Camera activates only after you tap Open Camera. Nothing is recorded automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let image = appState.camera.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 280)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                            Text("No capture yet")
                                .foregroundStyle(.secondary)
                        }
                    }
            }

            Button {
                Task { await appState.openCamera() }
            } label: {
                Label("Open Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            if let error = appState.camera.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(16)
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $appState.camera.showPicker) {
            CameraPicker(image: $appState.camera.capturedImage)
                .ignoresSafeArea()
        }
    }
}

struct DebugPanelView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("App State") {
                LabeledContent("Selected Tab", value: "\(appState.selectedTab)")
                LabeledContent("Refreshing", value: appState.isRefreshing ? "Yes" : "No")
                LabeledContent("Context", value: appState.lastContextMessage)
                LabeledContent("Events", value: "\(appState.storage.count)")
            }

            Section("Permissions") {
                ForEach(PermissionManager.PermissionKind.allCases) { kind in
                    LabeledContent(kind.title, value: (appState.permissions.statuses[kind] ?? .notDetermined).label)
                }
            }

            Section("Last Updates") {
                LabeledContent("Motion", value: stamp(appState.motion.lastUpdate))
                LabeledContent("HealthKit", value: stamp(appState.healthKit.lastUpdate))
                LabeledContent("Location", value: stamp(appState.location.lastUpdate))
                LabeledContent("Audio", value: stamp(appState.audio.lastUpdate))
                LabeledContent("Battery", value: stamp(appState.battery.lastUpdate))
            }

            Section {
                Button {
                    Task { await appState.refreshAllData() }
                } label: {
                    if appState.isRefreshing {
                        ProgressView()
                    } else {
                        Label("Refresh All Data", systemImage: "arrow.clockwise.circle.fill")
                    }
                }
                .disabled(appState.isRefreshing)
            }
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stamp(_ date: Date?) -> String {
        date?.formatted(date: .abbreviated, time: .standard) ?? "—"
    }
}
