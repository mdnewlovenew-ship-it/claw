import Foundation

enum MotionState: String, Codable, CaseIterable, Sendable {
    case stationary
    case walking
    case running
    case automotive
    case cycling
    case unknown

    var displayName: String {
        switch self {
        case .stationary: return "Sitting"
        case .walking: return "Walking"
        case .running: return "Running"
        case .automotive: return "Vehicle"
        case .cycling: return "Cycling"
        case .unknown: return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .automotive: return "car.fill"
        case .cycling: return "bicycle"
        case .unknown: return "questionmark.circle"
        }
    }
}
