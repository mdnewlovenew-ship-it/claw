import Foundation
import SwiftUI
import Combine

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

    @Published var selectedTab = 0
    @Published private(set) var currentSnapshot = SensorSnapshot.empty
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastContextMessage = "Waiting for first update"

    private var cancellables = Set<AnyCancellable>()
    private var clockTimer: Timer?

    @Published var now = Date()

    init() {
        bind()
        startClock()
        Task {
            await permissions.refreshNotificationStatus()
            await notifications.refresh()
            camera.refreshAuthorization()
            rebuildSnapshot()
        }
    }

    private func bind() {
        motion.configure { [weak self] state in
            self?.storage.append(
                eventType: "Motion changed",
                value: state.displayName,
                source: "CoreMotion"
            )
            self?.lastContextMessage = "Motion changed to \(state.displayName.lowercased())"
            self?.rebuildSnapshot()
        }

        motion.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        healthKit.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.rebuildSnapshot()
            }
            .store(in: &cancellables)

        location.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.rebuildSnapshot()
            }
            .store(in: &cancellables)

        audio.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.rebuildSnapshot()
            }
            .store(in: &cancellables)

        battery.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.rebuildSnapshot()
            }
            .store(in: &cancellables)

        storage.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        permissions.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        camera.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        notifications.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        device.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func startClock() {
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
    }

    func requestPermission(_ kind: PermissionManager.PermissionKind) async {
        switch kind {
        case .location:
            let ok = await location.requestWhenInUse()
            permissions.setStatus(ok ? .authorized : .denied, for: .location)
            if ok {
                location.refreshOnce()
                storage.append(eventType: "Permission granted", value: "Location", source: "PermissionManager")
            }
        case .motion:
            await permissions.request(.motion)
            motion.start()
            storage.append(eventType: "Permission granted", value: "Motion & Fitness", source: "PermissionManager")
            lastContextMessage = "Motion monitoring started"
        case .healthKit:
            let ok = await healthKit.requestAuthorization()
            permissions.setStatus(ok ? .authorized : .denied, for: .healthKit)
            if ok {
                storage.append(eventType: "Permission granted", value: "HealthKit", source: "PermissionManager")
                storage.append(eventType: "Health data refreshed", value: "Initial", source: "HealthKit")
                lastContextMessage = "Health data refreshed"
            }
        case .notifications:
            let ok = await notifications.requestAuthorization()
            permissions.setStatus(ok ? .authorized : .denied, for: .notifications)
            if ok {
                storage.append(eventType: "Permission granted", value: "Notifications", source: "PermissionManager")
            }
        case .microphone:
            await permissions.request(.microphone)
            if permissions.statuses[.microphone] == .authorized {
                storage.append(eventType: "Permission granted", value: "Microphone", source: "PermissionManager")
            }
        case .camera:
            await permissions.request(.camera)
            camera.refreshAuthorization()
            if permissions.statuses[.camera] == .authorized {
                storage.append(eventType: "Permission granted", value: "Camera", source: "PermissionManager")
            }
        }
        permissions.refreshAll()
        rebuildSnapshot()
    }

    func startVoiceRecording() {
        audio.startRecording()
        storage.append(eventType: "Voice recording started", value: "Recording", source: "AudioManager")
        lastContextMessage = "Voice recording started"
        rebuildSnapshot()
    }

    func stopVoiceRecording() {
        audio.stopRecording()
        let duration = Int(audio.metrics.duration)
        storage.append(
            eventType: "Voice recording stopped",
            value: "\(duration)s",
            source: "AudioManager"
        )
        lastContextMessage = "Voice recording stopped"
        rebuildSnapshot()
    }

    func openCamera() async {
        await camera.requestAccessAndOpen()
        if camera.showPicker {
            storage.append(eventType: "Camera opened", value: "Manual", source: "CameraManager")
            lastContextMessage = "Camera opened"
        }
    }

    func refreshAllData() async {
        isRefreshing = true
        defer { isRefreshing = false }

        battery.refresh()
        device.refresh()
        permissions.refreshAll()
        await permissions.refreshNotificationStatus()
        await notifications.refresh()
        camera.refreshAuthorization()

        if permissions.statuses[.motion] == .authorized || motion.isMonitoring {
            if !motion.isMonitoring {
                motion.start()
            }
        }

        if location.isAuthorized {
            location.refreshOnce()
        }

        if healthKit.authorizationRequested || permissions.statuses[.healthKit] == .authorized {
            await healthKit.refresh()
            storage.append(eventType: "Health data refreshed", value: "Manual", source: "HealthKit")
            lastContextMessage = "Health data refreshed"
        }

        rebuildSnapshot()
        storage.append(eventType: "Refresh all", value: "Manual", source: "AppState")
    }

    func buildCurrentSnapshot() -> SensorSnapshot {
        SensorSnapshot(
            timestamp: Date(),
            motionState: motion.motionState,
            steps: motion.steps ?? healthKit.snapshot.stepCount,
            distance: motion.distance ?? healthKit.snapshot.walkingRunningDistance,
            cadence: motion.cadence,
            batteryLevel: battery.level,
            charging: battery.isCharging,
            location: location.snapshot,
            heartRate: healthKit.snapshot.heartRate,
            bloodGlucose: healthKit.snapshot.bloodGlucose,
            activeEnergy: healthKit.snapshot.activeEnergy,
            voiceLevel: audio.metrics.averageLevel,
            isRecording: audio.isRecording,
            healthKitAvailable: healthKit.isAvailable,
            locationAvailable: location.isAuthorized
        )
    }

    func rebuildSnapshot() {
        currentSnapshot = buildCurrentSnapshot()
    }

    func refreshHealthData(source: String = "Health") async {
        await healthKit.refresh()
        storage.append(eventType: "Health data refreshed", value: source, source: "HealthKit")
        lastContextMessage = "Health data refreshed"
        rebuildSnapshot()
    }
}
