import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var latitude: Double?
    @Published private(set) var longitude: Double?
    @Published private(set) var accuracy: Double?
    @Published private(set) var timestamp: Date?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdate: Date?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Bool, Never>?

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var snapshot: LocationSnapshot? {
        guard let latitude, let longitude, let accuracy, let timestamp else { return nil }
        return LocationSnapshot(
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            timestamp: timestamp
        )
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.pausesLocationUpdatesAutomatically = true
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUse() async -> Bool {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            authorizationStatus = status
            return true
        }
        if status == .denied || status == .restricted {
            authorizationStatus = status
            lastError = "Location permission denied. Enable it in Settings."
            return false
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func refreshOnce() {
        guard isAuthorized else {
            lastError = "Location not authorized."
            return
        }
        lastError = nil
        manager.requestLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if let continuation {
                let ok = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
                continuation.resume(returning: ok)
                self.continuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            accuracy = location.horizontalAccuracy
            timestamp = location.timestamp
            lastUpdate = Date()
            lastError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
        }
    }
}
