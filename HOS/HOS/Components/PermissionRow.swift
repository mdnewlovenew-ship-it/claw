import SwiftUI

struct PermissionRow: View {
    let kind: PermissionManager.PermissionKind
    let status: PermissionManager.PermissionStatus
    let isBusy: Bool
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind.systemImage)
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.headline)
                    Text(kind.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                StatusIndicator(status: status)
            }

            Button(action: onRequest) {
                HStack {
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text(buttonTitle)
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .disabled(status == .authorized || status == .unavailable || isBusy)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var buttonTitle: String {
        switch status {
        case .authorized: return "Authorized"
        case .unavailable: return "Unavailable"
        case .denied, .restricted: return "Open Settings"
        case .notDetermined: return "Request Access"
        }
    }
}
