import SwiftUI

struct StatusIndicator: View {
    let status: PermissionManager.PermissionStatus

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
        case .notDetermined: return .orange
        case .unavailable: return .secondary
        }
    }

    private var background: Color {
        foreground.opacity(0.15)
    }
}

struct LiveDot: View {
    var color: Color = .green

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}
