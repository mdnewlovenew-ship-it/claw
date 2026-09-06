import SwiftUI

struct StatusIndicator: View {
    let status: HOSPermissionStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch status {
        case .authorized: return .green
        case .denied, .restricted: return .red
        case .unavailable: return .secondary
        case .notDetermined: return .orange
        }
    }

    private var background: Color {
        foreground.opacity(0.15)
    }
}
