import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject private var app: AppState
    @State private var busy: HOSPermissionKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Grant only what you need. Nothing is requested until you tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(HOSPermissionKind.allCases) { kind in
                    PermissionRow(
                        kind: kind,
                        status: app.permissions.status(for: kind),
                        isBusy: busy == kind
                    ) {
                        Task {
                            busy = kind
                            await app.requestPermission(kind)
                            busy = nil
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Permissions")
        .onAppear { app.permissions.refreshAll() }
    }
}
