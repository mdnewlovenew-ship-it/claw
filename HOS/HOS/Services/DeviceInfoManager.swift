import Foundation
import UIKit

@MainActor
final class DeviceInfoManager: ObservableObject {
    @Published private(set) var modelName: String = "iPhone"
    @Published private(set) var systemVersion: String = UIDevice.current.systemVersion
    @Published private(set) var systemName: String = UIDevice.current.systemName
    @Published private(set) var name: String = UIDevice.current.name

    init() {
        refresh()
    }

    func refresh() {
        systemVersion = UIDevice.current.systemVersion
        systemName = UIDevice.current.systemName
        name = UIDevice.current.name
        modelName = Self.safeModelIdentifier()
    }

    /// Prefer a stable hardware identifier via uname without private APIs.
    private static func safeModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            if let value = element.value as? Int8, value != 0 {
                result.append(Character(UnicodeScalar(UInt8(value))))
            }
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }
}
