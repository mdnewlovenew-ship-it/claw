import Foundation
import CoreMotion

@MainActor
final class MotionManager: ObservableObject {
    @Published private(set) var motionState: MotionState = .unknown
    @Published private(set) var steps: Double?
    @Published private(set) var distance: Double?
    @Published private(set) var cadence: Double?
    @Published private(set) var isAvailable: Bool = false
    @Published private(set) var isMonitoring = false
    @Published private(set) var lastUpdate: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var confidence: String = "low"

    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    private var onStateChange: ((MotionState) -> Void)?

    func configure(onStateChange: @escaping (MotionState) -> Void) {
        self.onStateChange = onStateChange
    }

    func start() {
        isAvailable = CMMotionActivityManager.isActivityAvailable() || CMPedometer.isStepCountingAvailable()
        guard isAvailable else {
            lastError = "Motion sensors are unavailable on this device."
            motionState = .unknown
            return
        }

        stop()
        isMonitoring = true
        lastError = nil

        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self, let activity else { return }
                Task { @MainActor in
                    let previous = self.motionState
                    let next = Self.map(activity)
                    self.motionState = next
                    self.confidence = Self.confidenceLabel(activity.confidence)
                    self.lastUpdate = Date()
                    if previous != next {
                        self.onStateChange?(next)
                    }
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
                        return
                    }
                    guard let data else { return }
                    self.steps = data.numberOfSteps.doubleValue
                    if CMPedometer.isDistanceAvailable() {
                        self.distance = data.distance?.doubleValue
                    }
                    if CMPedometer.isCadenceAvailable() {
                        self.cadence = data.currentCadence?.doubleValue
                    }
                    self.lastUpdate = Date()
                }
            }
        }
    }

    func stop() {
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

    private static func confidenceLabel(_ confidence: CMMotionActivityConfidence) -> String {
        switch confidence {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        @unknown default: return "unknown"
        }
    }
}
