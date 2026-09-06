import SwiftUI
import UIKit

struct PermissionRow: View {
    let kind: HOSPermissionKind
    let status: HOSPermissionStatus
    let isBusy: Bool
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind.systemImage)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.headline)
                    Text(kind.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                StatusIndicator(status: status)
            }

            Button(action: {
                if status == .denied || status == .restricted {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    onRequest()
                }
            }) {
                HStack {
                    if isBusy {
                        ProgressView()
                    }
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(status == .authorized || status == .unavailable || isBusy)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var buttonTitle: String {
        switch status {
        case .authorized: return "Enabled"
        case .unavailable: return "Unavailable"
        case .denied, .restricted: return "Open Settings Needed"
        case .notDetermined: return "Request Permission"
        }
    }
}
