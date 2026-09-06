import Foundation
import Combine
import CoreLocation

@MainActor
final class AppState: ObservableObject {
    let permissions = PermissionManager()
    let healthKit = HealthKitManager()
    let motion = MotionManager()
    let location = LocationManager()
    let audio = AudioManager()
    let camera = CameraManager()
    let notifications = NotificationManager()
    let battery = BatteryMonitor()
    let device = DeviceInfoManager()
    let storage = LocalStorageManager()

    @Published var currentSnapshot = SensorSnapshot.empty
    @Published var lastContextMessage: String = "Waiting for first update"
    @Published private(set) var lastRefreshAll: Date?

    private var cancellables = Set<AnyCancellable>()
    private var previousMotion: MotionState = .unknown

    init() {
        bind()
        rebuildSnapshot()
    }

    func bind() {
        Publishers.MergeMany(
            motion.objectWillChange.map { _ in () },
            healthKit.objectWillChange.map { _ in () },
            location.objectWillChange.map { _ in () },
            audio.objectWillChange.map { _ in () },
            battery.objectWillChange.map { _ in () },
            permissions.objectWillChange.map { _ in () }
        )
        .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
        .sink { [weak self] in
            self?.rebuildSnapshot()
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)

        motion.$motionState
            .removeDuplicates()
            .sink { [weak self] state in
                guard let self else { return }
                if state != self.previousMotion {
                    self.previousMotion = state
                    self.record(
                        type: "Motion changed",
                        value: "Motion changed to \(state.displayName.lowercased())",
                        source: "Motion"
                    )
                }
            }
            .store(in: &cancellables)

        audio.$isRecording
            .removeDuplicates()
            .sink { [weak self] recording in
                guard let self else { return }
                if recording {
                    self.record(type: "Voice recording started", value: "Recording started", source: "Voice")
                } else if self.audio.metrics.duration > 0 {
                    self.record(type: "Voice recording stopped", value: "Recording stopped", source: "Voice")
                }
            }
            .store(in: &cancellables)
    }

    func buildCurrentSnapshot() -> SensorSnapshot {
        SensorSnapshot(
            timestamp: Date(),
            motionState: motion.motionState,
            steps: motion.steps ?? healthKit.snapshot.stepCount,
            distance: motion.distanceMeters ?? healthKit.snapshot.walkingRunningDistanceMeters,
            cadence: motion.cadence,
            batteryLevel: battery.level,
            charging: battery.isCharging,
            location: location.snapshot,
            heartRate: healthKit.snapshot.heartRate,
            bloodGlucose: healthKit.snapshot.bloodGlucoseMgDl,
            activeEnergy: healthKit.snapshot.activeEnergyKilocalories,
            voiceLevel: audio.metrics.averageLevel,
            isRecording: audio.isRecording,
            healthKitAvailable: healthKit.isAvailable,
            locationAvailable: location.isAuthorized && location.snapshot != nil
        )
    }

    func rebuildSnapshot() {
        currentSnapshot = buildCurrentSnapshot()
    }

    func record(type: String, value: String, source: String) {
        storage.append(eventType: type, value: value, source: source)
        lastContextMessage = value
        rebuildSnapshot()
    }

    func refreshAllData() async {
        permissions.refreshAll()
        battery.refresh()
        device.refresh()
        camera.refreshAuthorization()
        await notifications.refresh()

        if motion.isAvailable && motion.isAuthorized {
            motion.startMonitoring()
        }
        if location.isAuthorized {
            location.refreshOnce()
        }
        if healthKit.isAuthorized || healthKit.isAvailable {
            await healthKit.refresh()
            record(type: "Health data refreshed", value: "Health data refreshed", source: "HealthKit")
        }

        audio.refreshRecordingList()
        rebuildSnapshot()
        lastRefreshAll = Date()
        record(type: "Refresh all", value: "Manual refresh of all available sensors", source: "Debug")
    }

    func requestPermission(_ kind: HOSPermissionKind) async {
        switch kind {
        case .microphone:
            await permissions.request(.microphone)
            permissions.refreshAll()
        case .camera:
            await permissions.request(.camera)
            camera.refreshAuthorization()
            permissions.refreshAll()
        case .location:
            location.requestWhenInUse()
            // Status updates via delegate; sync shortly after.
            try? await Task.sleep(nanoseconds: 400_000_000)
            permissions.setStatus(
                location.isAuthorized ? .authorized :
                    (location.authorizationStatus == .denied || location.authorizationStatus == .restricted
                     ? (location.authorizationStatus == .restricted ? .restricted : .denied)
                     : .notDetermined),
                for: .location
            )
            if location.isAuthorized {
                location.refreshOnce()
            }
        case .motion:
            motion.requestAccessAndStart()
            permissions.setStatus(motion.isAvailable ? (motion.isAuthorized ? .authorized : .notDetermined) : .unavailable, for: .motion)
            // Pedometer callback may flip auth later.
            try? await Task.sleep(nanoseconds: 600_000_000)
            if motion.isAuthorized {
                permissions.setStatus(.authorized, for: .motion)
            } else if motion.lastError != nil {
                permissions.setStatus(.denied, for: .motion)
            }
        case .notifications:
            let granted = await notifications.requestAuthorization()
            permissions.setStatus(granted ? .authorized : .denied, for: .notifications)
        case .healthKit:
            let granted = await healthKit.requestAuthorization()
            permissions.setStatus(
                healthKit.isAvailable ? (granted ? .authorized : .denied) : .unavailable,
                for: .healthKit
            )
            if granted {
                record(type: "Health data refreshed", value: "HealthKit authorization granted", source: "HealthKit")
            }
        }
        rebuildSnapshot()
    }
}
