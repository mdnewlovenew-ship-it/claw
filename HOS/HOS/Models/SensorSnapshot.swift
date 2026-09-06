import Foundation
import CoreLocation

struct LocationSnapshot: Codable, Equatable, Sendable {
    var latitude: Double
    var longitude: Double
    var accuracy: Double
    var timestamp: Date

    var isValid: Bool {
        accuracy >= 0 && CLLocationCoordinate2DIsValid(
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        )
    }
}

struct SensorSnapshot: Codable, Equatable, Sendable {
    var timestamp: Date
    var motionState: MotionState
    var steps: Double?
    var distance: Double?
    var cadence: Double?
    var batteryLevel: Float
    var charging: Bool
    var location: LocationSnapshot?
    var heartRate: Double?
    var bloodGlucose: Double?
    var activeEnergy: Double?
    var voiceLevel: Float
    var isRecording: Bool
    var healthKitAvailable: Bool
    var locationAvailable: Bool

    static let empty = SensorSnapshot(
        timestamp: Date(),
        motionState: .unknown,
        steps: nil,
        distance: nil,
        cadence: nil,
        batteryLevel: -1,
        charging: false,
        location: nil,
        heartRate: nil,
        bloodGlucose: nil,
        activeEnergy: nil,
        voiceLevel: 0,
        isRecording: false,
        healthKitAvailable: false,
        locationAvailable: false
    )
}
