import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    @Published private(set) var snapshot = HealthSnapshot.empty
    @Published private(set) var isAvailable: Bool = HKHealthStore.isHealthDataAvailable()
    @Published private(set) var authorizationRequested = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdate: Date?

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

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            lastError = "HealthKit is not available on this device."
            return false
        }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            authorizationRequested = true
            lastError = nil
            await refresh()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func refresh() async {
        guard isAvailable else { return }

        async let steps = latestQuantity(.stepCount, unit: .count())
        async let distance = latestQuantity(.distanceWalkingRunning, unit: .meter())
        async let energy = latestQuantity(.activeEnergyBurned, unit: .kilocalorie())
        async let heart = latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let resting = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let walkingHR = latestQuantity(.walkingHeartRateAverage, unit: HKUnit.count().unitDivided(by: .minute()))
        async let glucose = latestQuantity(
            .bloodGlucose,
            unit: HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))
        )
        async let mass = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let spo2 = latestQuantity(.oxygenSaturation, unit: .percent())
        async let sleep = latestSleepHours()

        let stepsResult = await steps
        let distanceResult = await distance
        let energyResult = await energy
        let heartResult = await heart
        let restingResult = await resting
        let walkingHRResult = await walkingHR
        let glucoseResult = await glucose
        let massResult = await mass
        let spo2Result = await spo2
        let sleepResult = await sleep

        var next = HealthSnapshot.empty
        next.lastUpdated = Date()
        next.stepCount = stepsResult?.value
        next.stepCountDate = stepsResult?.date
        next.walkingRunningDistance = distanceResult?.value
        next.walkingRunningDistanceDate = distanceResult?.date
        next.activeEnergy = energyResult?.value
        next.activeEnergyDate = energyResult?.date
        next.heartRate = heartResult?.value
        next.heartRateDate = heartResult?.date
        next.restingHeartRate = restingResult?.value
        next.restingHeartRateDate = restingResult?.date
        next.walkingHeartRateAverage = walkingHRResult?.value
        next.walkingHeartRateAverageDate = walkingHRResult?.date
        next.bloodGlucose = glucoseResult?.value
        next.bloodGlucoseDate = glucoseResult?.date
        next.bodyMass = massResult?.value
        next.bodyMassDate = massResult?.date
        if let spo2Result {
            next.oxygenSaturation = spo2Result.value * 100
            next.oxygenSaturationDate = spo2Result.date
        }
        next.sleepHours = sleepResult?.value
        next.sleepDate = sleepResult?.date

        snapshot = next
        lastUpdate = Date()
        lastError = nil
    }

    private func latestQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async -> (value: Double, date: Date)? {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (sample.quantity.doubleValue(for: unit), sample.endDate))
            }
            self.store.execute(query)
        }
    }

    private func latestSleepHours() async -> (value: Double, date: Date)? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        return await withCheckedContinuation { continuation in
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -2, to: end) ?? end
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
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
                continuation.resume(returning: (hours, samples.first?.endDate ?? end))
            }
            self.store.execute(query)
        }
    }
}
