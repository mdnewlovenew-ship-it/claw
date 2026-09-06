import Foundation
import CoreMotion

@MainActor
final class MotionManager: ObservableObject {
    @Published private(set) var motionState: MotionState = .unknown
    @Published private(set) var steps: Double?
    @Published private(set) var distanceMeters: Double?
    @Published private(set) var cadence: Double?
    @Published private(set) var isAvailable = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isMonitoring = false

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()

    init() {
        isAvailable = CMMotionActivityManager.isActivityAvailable() || CMPedometer.isStepCountingAvailable()
    }

    func requestAccessAndStart() {
        guard isAvailable else {
            lastError = "Motion & Fitness sensors are unavailable."
            return
        }
        startMonitoring()
    }

    func startMonitoring() {
        guard isAvailable else { return }
        stopMonitoring()
        isMonitoring = true

        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self, let activity else { return }
                Task { @MainActor in
                    self.motionState = Self.map(activity)
                    self.isAuthorized = true
                    self.lastUpdated = Date()
                    self.lastError = nil
                }
            }
        }

        if CMPedometer.isStepCountingAvailable() {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.lastError = error.localizedDescription
                        // Permission denial often surfaces here.
                        if (error as NSError).domain == CMErrorDomain {
                            self.isAuthorized = false
                        }
                        return
                    }
                    guard let data else { return }
                    self.steps = data.numberOfSteps.doubleValue
                    self.distanceMeters = data.distance?.doubleValue
                    self.cadence = data.currentCadence?.doubleValue
                    self.isAuthorized = true
                    self.lastUpdated = Date()
                    self.lastError = nil
                }
            }
        }
    }

    func stopMonitoring() {
        activityManager.stopActivityUpdates()
        pedometer.stopUpdates()
        isMonitoring = false
    }

    private static func map(_ activity: CMMotionActivity) -> MotionState {
        if activity.running { return .running }
        if activity.cycling { return .cycling }
        if activity.automotive { return .automotive }
        if activity.walking { return .walking }
        if activity.stationary { return .stationary }
        return .unknown
    }
}
