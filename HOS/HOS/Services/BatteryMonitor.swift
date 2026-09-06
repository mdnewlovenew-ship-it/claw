import Foundation
import UIKit

final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float = -1
    @Published private(set) var state: UIDevice.BatteryState = .unknown
    @Published private(set) var isCharging = false
    @Published private(set) var lastUpdated: Date?

    private var levelObserver: NSObjectProtocol?
    private var stateObserver: NSObjectProtocol?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()
        let center = NotificationCenter.default
        levelObserver = center.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        stateObserver = center.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        let center = NotificationCenter.default
        if let levelObserver { center.removeObserver(levelObserver) }
        if let stateObserver { center.removeObserver(stateObserver) }
    }

    func refresh() {
        let device = UIDevice.current
        level = device.batteryLevel
        state = device.batteryState
        isCharging = device.batteryState == .charging || device.batteryState == .full
        lastUpdated = Date()
    }

    var percentageText: String {
        guard level >= 0 else { return "—" }
        return "\(Int((level * 100).rounded()))%"
    }

    var stateText: String {
        switch state {
        case .charging: return "Charging"
        case .full: return "Full"
        case .unplugged: return "Unplugged"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
