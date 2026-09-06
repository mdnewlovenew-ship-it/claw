import Foundation
import AVFoundation
import CoreLocation
import CoreMotion
import UserNotifications
import UIKit

@MainActor
final class PermissionManager: ObservableObject {
    enum PermissionKind: String, CaseIterable, Identifiable {
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

        var description: String {
            switch self {
            case .microphone:
                return "Record short voice samples for local voice metrics. Audio never leaves your device."
            case .camera:
                return "Open the camera only when you choose to capture a photo. Nothing is recorded automatically."
            case .location:
                return "Read your location while using the app to enrich local context. No background tracking."
            case .motion:
                return "Detect sitting, walking, running, and vehicle states using Core Motion."
            case .notifications:
                return "Optional local reminders. No remote push required for MVP."
            case .healthKit:
                return "Read selected health metrics from Apple Health. Read-only for MVP. Not a diagnostic tool."
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

    enum PermissionStatus: String, Codable {
        case notDetermined
        case authorized
        case denied
        case restricted
        case unavailable

        var label: String {
            switch self {
            case .notDetermined: return "Not Requested"
            case .authorized: return "Authorized"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .unavailable: return "Unavailable"
            }
        }
    }

    @Published private(set) var statuses: [PermissionKind: PermissionStatus] = [:]

    init() {
        refreshAll()
    }

    func refreshAll() {
        for kind in PermissionKind.allCases {
            statuses[kind] = currentStatus(for: kind)
        }
    }

    func currentStatus(for kind: PermissionKind) -> PermissionStatus {
        switch kind {
        case .microphone:
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return .authorized
            case .denied: return .denied
            case .undetermined: return .notDetermined
            @unknown default: return .unavailable
            }
        case .camera:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: return .authorized
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .unavailable
            }
        case .location:
            switch CLLocationManager().authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways: return .authorized
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .unavailable
            }
        case .motion:
            if !CMMotionActivityManager.isActivityAvailable() {
                return .unavailable
            }
            // Core Motion does not expose a sync auth status API on all OS versions.
            // We treat availability as notDetermined until the user triggers a request.
            return statuses[.motion] ?? .notDetermined
        case .notifications:
            // Async status is refreshed after request; default notDetermined until checked.
            return statuses[.notifications] ?? .notDetermined
        case .healthKit:
            return statuses[.healthKit] ?? .notDetermined
        }
    }

    func request(_ kind: PermissionKind) async {
        switch kind {
        case .microphone:
            let granted = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            statuses[.microphone] = granted ? .authorized : .denied
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            statuses[.camera] = granted ? .authorized : .denied
        case .location:
            // Location request is handled by LocationManager to keep a single CLLocationManager.
            statuses[.location] = currentStatus(for: .location)
        case .motion:
            if CMMotionActivityManager.isActivityAvailable() {
                statuses[.motion] = .authorized
            } else {
                statuses[.motion] = .unavailable
            }
        case .notifications:
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                statuses[.notifications] = granted ? .authorized : .denied
            } catch {
                statuses[.notifications] = .denied
            }
        case .healthKit:
            // HealthKit request is performed by HealthKitManager.
            break
        }
        refreshAll()
    }

    func setStatus(_ status: PermissionStatus, for kind: PermissionKind) {
        statuses[kind] = status
    }

    func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            statuses[.notifications] = .authorized
        case .denied:
            statuses[.notifications] = .denied
        case .notDetermined:
            statuses[.notifications] = .notDetermined
        @unknown default:
            statuses[.notifications] = .unavailable
        }
    }
}
