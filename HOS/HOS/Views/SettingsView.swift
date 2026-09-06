import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppState
    @State private var refreshing = false

    var body: some View {
        NavigationStack {
            List {
                Section("Access") {
                    NavigationLink("Permission Center") {
                        PermissionsView()
                    }
                    NavigationLink("Sensor Snapshot") {
                        SensorsView()
                    }
                }

                Section("Camera") {
                    Text("Camera opens only after you tap. No automatic capture.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Camera") {
                        Task {
                            if app.permissions.status(for: .camera) != .authorized {
                                await app.requestPermission(.camera)
                            }
                            app.camera.openCamera()
                        }
                    }
                    if let error = app.camera.lastError {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                    if let image = app.camera.lastCapturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Section("Device") {
                    LabeledContent("Model", value: app.device.deviceModel)
                    LabeledContent("System", value: "iOS \(app.device.systemVersion)")
                    LabeledContent("Battery", value: "\(app.battery.percentageText) · \(app.battery.stateText)")
                }

                Section("Privacy") {
                    Text("All MVP data stays locally on this iPhone.")
                    Text("No cloud upload.")
                    Text("No advertising.")
                    Text("No analytics SDK.")
                    Text("No remote tracking.")
                    Text("You control every permission. Nothing is requested automatically on launch.")
                }
                .font(.subheadline)

                Section("Developer / Debug") {
                    debugRow("App state", "Running · snapshot \(app.currentSnapshot.timestamp.formatted(date: .omitted, time: .standard))")
                    debugRow("Mic", app.permissions.status(for: .microphone).label)
                    debugRow("Camera", app.permissions.status(for: .camera).label)
                    debugRow("Location", app.permissions.status(for: .location).label)
                    debugRow("Motion", app.permissions.status(for: .motion).label)
                    debugRow("Notifications", app.permissions.status(for: .notifications).label)
                    debugRow("HealthKit", app.permissions.status(for: .healthKit).label)
                    debugRow("Last motion", app.motion.lastUpdated?.formatted() ?? "—")
                    debugRow("Last HealthKit", app.healthKit.lastUpdated?.formatted() ?? "—")
                    debugRow("Last location", app.location.timestamp?.formatted() ?? "—")
                    debugRow("Last audio", app.audio.lastUpdated?.formatted() ?? "—")
                    debugRow("ContextEvents", "\(app.storage.count)")

                    Button {
                        Task {
                            refreshing = true
                            await app.refreshAllData()
                            refreshing = false
                        }
                    } label: {
                        HStack {
                            Text("REFRESH ALL DATA")
                                .fontWeight(.semibold)
                            if refreshing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }

                    Button("Send Local Notification Test") {
                        Task {
                            if !app.notifications.isAuthorized {
                                await app.requestPermission(.notifications)
                            }
                            await app.notifications.scheduleLocalSmokeTest()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: Binding(
                get: { app.camera.isPresented },
                set: { app.camera.isPresented = $0 }
            )) {
                CameraPicker(manager: app.camera)
                    .ignoresSafeArea()
            }
        }
    }

    private func debugRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.footnote)
    }
}
