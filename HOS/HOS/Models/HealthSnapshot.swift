import Foundation

struct HealthSnapshot: Codable, Equatable, Sendable {
    var stepCount: Double?
    var walkingRunningDistanceMeters: Double?
    var activeEnergyKilocalories: Double?
    var heartRate: Double?
    var restingHeartRate: Double?
    var walkingHeartRateAverage: Double?
    var bloodGlucoseMgDl: Double?
    var bodyMassKg: Double?
    var oxygenSaturation: Double?
    var sleepHours: Double?

    var stepCountDate: Date?
    var walkingRunningDistanceDate: Date?
    var activeEnergyDate: Date?
    var heartRateDate: Date?
    var restingHeartRateDate: Date?
    var walkingHeartRateAverageDate: Date?
    var bloodGlucoseDate: Date?
    var bodyMassDate: Date?
    var oxygenSaturationDate: Date?
    var sleepDate: Date?

    var lastUpdated: Date?

    static let empty = HealthSnapshot()
}
