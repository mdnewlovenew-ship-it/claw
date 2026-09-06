import SwiftUI
import UIKit

struct PermissionsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var busyKind: PermissionManager.PermissionKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Permission Center")
                    .font(.title2.bold())
                Text("HOS never requests permissions automatically. Each sensor stays off until you press Request Access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(PermissionManager.PermissionKind.allCases) { kind in
                    PermissionRow(
                        kind: kind,
                        status: appState.permissions.statuses[kind] ?? .notDetermined,
                        isBusy: busyKind == kind
                    ) {
                        handle(kind)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appState.permissions.refreshAll()
            Task { await appState.permissions.refreshNotificationStatus() }
            if appState.healthKit.authorizationRequested {
                appState.permissions.setStatus(.authorized, for: .healthKit)
            }
            if appState.motion.isMonitoring {
                appState.permissions.setStatus(.authorized, for: .motion)
            }
        }
    }

    private func handle(_ kind: PermissionManager.PermissionKind) {
        let status = appState.permissions.statuses[kind] ?? .notDetermined
        if status == .denied || status == .restricted {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }
        busyKind = kind
        Task {
            await appState.requestPermission(kind)
            busyKind = nil
        }
    }
}
