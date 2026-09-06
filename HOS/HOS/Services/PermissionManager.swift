import Foundation
import AVFoundation
import CoreLocation
import CoreMotion
import HealthKit
import UserNotifications
import UIKit

enum HOSPermissionKind: String, CaseIterable, Identifiable, Codable {
    case microphone
    case camera
    case location
    case motion
    case notifications
    case healthKit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .microphone: return "Microphone"
        case .camera: return "Camera"
        case .location: return "Location"
        case .motion: return "Motion & Fitness"
        case .notifications: return "Notifications"
        case .healthKit: return "HealthKit"
        }
    }

    var detail: String {
        switch self {
        case .microphone:
            return "Record short voice samples locally for level metrics. Audio never leaves your iPhone."
        case .camera:
            return "Open the camera only when you tap Capture. Nothing is recorded automatically."
        case .location:
            return "Read your current location while the app is open (When In Use)."
        case .motion:
            return "Detect activity state, steps, and cadence using Core Motion."
        case .notifications:
            return "Optional local reminders. No remote push in this MVP."
        case .healthKit:
            return "Read selected health samples you choose to share. Read-only for MVP."
        }
    }

    var systemImage: String {
        switch self {
        case .microphone: return "mic.fill"
        case .camera: return "camera.fill"
        case .location: return "location.fill"
        case .motion: return "figure.walk"
        case .notifications: return "bell.fill"
        case .healthKit: return "heart.fill"
        }
    }
}

enum HOSPermissionStatus: String, Codable {
    case notDetermined
    case denied
    case authorized
    case restricted
    case unavailable

    var label: String {
        switch self {
        case .notDetermined: return "Not Requested"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .restricted: return "Restricted"
        case .unavailable: return "Unavailable"
        }
    }
}

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var statuses: [HOSPermissionKind: HOSPermissionStatus] = [:]

    init() {
        for kind in HOSPermissionKind.allCases {
            statuses[kind] = .notDetermined
        }
        refreshAll()
    }

    func status(for kind: HOSPermissionKind) -> HOSPermissionStatus {
        statuses[kind] ?? .notDetermined
    }

    func refreshAll() {
        statuses[.microphone] = microphoneStatus()
        statuses[.camera] = cameraStatus()
        statuses[.location] = locationStatus()
        statuses[.motion] = motionStatus()
        statuses[.notifications] = .notDetermined
        statuses[.healthKit] = healthKitStatus()
        Task { await refreshNotificationStatus() }
    }

    func request(_ kind: HOSPermissionKind) async {
        switch kind {
        case .microphone:
            let granted = await AVAudioApplication.requestRecordPermission()
            statuses[.microphone] = granted ? .authorized : .denied
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            statuses[.camera] = granted ? .authorized : .denied
        case .location:
            break // LocationManager owns the request flow
        case .motion:
            break // MotionManager owns the request flow via first query
        case .notifications:
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                statuses[.notifications] = granted ? .authorized : .denied
            } catch {
                statuses[.notifications] = .denied
            }
        case .healthKit:
            break // HealthKitManager owns authorization
        }
    }

    func setStatus(_ status: HOSPermissionStatus, for kind: HOSPermissionKind) {
        statuses[kind] = status
    }

    private func microphoneStatus() -> HOSPermissionStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined: return .notDetermined
        case .denied: return .denied
        case .granted: return .authorized
        @unknown default: return .unavailable
        }
    }

    private func cameraStatus() -> HOSPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .restricted: return .restricted
        @unknown default: return .unavailable
        }
    }

    private func locationStatus() -> HOSPermissionStatus {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        @unknown default: return .unavailable
        }
    }

    private func motionStatus() -> HOSPermissionStatus {
        if !CMMotionActivityManager.isActivityAvailable() && !CMPedometer.isStepCountingAvailable() {
            return .unavailable
        }
        // Core Motion does not expose a public auth status API on all OS versions.
        // We treat availability as notDetermined until MotionManager reports success/failure.
        return statuses[.motion] ?? .notDetermined
    }

    private func healthKitStatus() -> HOSPermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
        return statuses[.healthKit] ?? .notDetermined
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            statuses[.notifications] = .notDetermined
        case .denied:
            statuses[.notifications] = .denied
        case .authorized, .provisional, .ephemeral:
            statuses[.notifications] = .authorized
        @unknown default:
            statuses[.notifications] = .unavailable
        }
    }
}
