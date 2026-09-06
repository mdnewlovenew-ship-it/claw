import Foundation

struct HealthSnapshot: Codable, Equatable, Sendable {
    var stepCount: Double?
    var stepCountDate: Date?
    var walkingRunningDistance: Double?
    var walkingRunningDistanceDate: Date?
    var activeEnergy: Double?
    var activeEnergyDate: Date?
    var heartRate: Double?
    var heartRateDate: Date?
    var restingHeartRate: Double?
    var restingHeartRateDate: Date?
    var walkingHeartRateAverage: Double?
    var walkingHeartRateAverageDate: Date?
    var bloodGlucose: Double?
    var bloodGlucoseDate: Date?
    var bodyMass: Double?
    var bodyMassDate: Date?
    var sleepHours: Double?
    var sleepDate: Date?
    var oxygenSaturation: Double?
    var oxygenSaturationDate: Date?
    var lastUpdated: Date?

    static let empty = HealthSnapshot()
}
