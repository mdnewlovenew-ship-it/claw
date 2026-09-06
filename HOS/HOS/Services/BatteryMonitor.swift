import Foundation
import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float = -1
    @Published private(set) var isCharging = false
    @Published private(set) var stateLabel = "Unknown"
    @Published private(set) var lastUpdate: Date?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func refresh() {
        let device = UIDevice.current
        level = device.batteryLevel
        switch device.batteryState {
        case .charging:
            isCharging = true
            stateLabel = "Charging"
        case .full:
            isCharging = true
            stateLabel = "Full"
        case .unplugged:
            isCharging = false
            stateLabel = "Unplugged"
        case .unknown:
            isCharging = false
            stateLabel = "Unknown"
        @unknown default:
            isCharging = false
            stateLabel = "Unknown"
        }
        lastUpdate = Date()
    }

    var percentageText: String {
        guard level >= 0 else { return "—" }
        return "\(Int((level * 100).rounded()))%"
    }
}
