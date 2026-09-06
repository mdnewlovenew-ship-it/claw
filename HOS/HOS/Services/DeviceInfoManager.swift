import Foundation
import UIKit

@MainActor
final class DeviceInfoManager: ObservableObject {
    @Published private(set) var systemVersion: String = ""
    @Published private(set) var deviceModel: String = ""
    @Published private(set) var deviceName: String = ""

    init() {
        refresh()
    }

    func refresh() {
        let device = UIDevice.current
        systemVersion = device.systemVersion
        deviceName = device.name
        deviceModel = Self.safeModelIdentifier()
    }

    /// Returns a stable hardware identifier via `uname` / machine string.
    /// Avoids private APIs.
    private static func safeModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return partial }
            return partial + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
