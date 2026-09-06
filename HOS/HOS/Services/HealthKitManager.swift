import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty
    @Published private(set) var isAvailable = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdated: Date?

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .heartRate,
            .restingHeartRate,
            .walkingHeartRateAverage,
            .bloodGlucose,
            .bodyMass,
            .oxygenSaturation
        ]
        for id in identifiers {
            if let type = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }

    init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            lastError = "HealthKit is unavailable on this device."
            return false
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            lastError = nil
            await refresh()
            return true
        } catch {
            isAuthorized = false
            lastError = error.localizedDescription
            return false
        }
    }

    func refresh() async {
        guard isAvailable else { return }
        var next = HealthSnapshot.empty
        next.lastUpdated = Date()

        next.stepCount = await latestSum(.stepCount, unit: .count(), since: Calendar.current.startOfDay(for: Date()))
        next.stepCountDate = next.stepCount == nil ? nil : Date()

        let distance = await latestSum(.distanceWalkingRunning, unit: .meter(), since: Calendar.current.startOfDay(for: Date()))
        next.walkingRunningDistanceMeters = distance
        next.walkingRunningDistanceDate = distance == nil ? nil : Date()

        let energy = await latestSum(.activeEnergyBurned, unit: .kilocalorie(), since: Calendar.current.startOfDay(for: Date()))
        next.activeEnergyKilocalories = energy
        next.activeEnergyDate = energy == nil ? nil : Date()

        if let sample = await latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            next.heartRate = sample.value
            next.heartRateDate = sample.date
        }
        if let sample = await latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute())) {
            next.restingHeartRate = sample.value
            next.restingHeartRateDate = sample.date
        }
        if let sample = await latestQuantity(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute())) {
            next.walkingHeartRateAverage = sample.value
            next.walkingHeartRateAverageDate = sample.date
        }
        if let sample = await latestQuantity(
            .bloodGlucose,
            unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        ) {
            next.bloodGlucoseMgDl = sample.value
            next.bloodGlucoseDate = sample.date
        }
        if let sample = await latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo)) {
            next.bodyMassKg = sample.value
            next.bodyMassDate = sample.date
        }
        if let sample = await latestQuantity(.oxygenSaturation, unit: .percent()) {
            next.oxygenSaturation = sample.value * 100
            next.oxygenSaturationDate = sample.date
        }
        if let sleep = await latestSleepHours() {
            next.sleepHours = sleep.value
            next.sleepDate = sleep.date
        }

        snapshot = next
        lastUpdated = Date()
        lastError = nil
    }

    private func latestSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, since start: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> (value: Double, date: Date)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.endDate))
            }
            store.execute(query)
        }
    }

    private func latestSleepHours() async -> (value: Double, date: Date)? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                let hours = total / 3600.0
                continuation.resume(returning: hours > 0 ? (hours, samples.first?.endDate ?? Date()) : nil)
            }
            store.execute(query)
        }
    }
}
