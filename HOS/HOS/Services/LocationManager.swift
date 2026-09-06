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
    @Published private(set) var isUpdating = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.pausesLocationUpdatesAutomatically = true
        authorizationStatus = manager.authorizationStatus
    }

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

    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    func refreshOnce() {
        guard isAuthorized else {
            lastError = "Location permission is not granted."
            return
        }
        isUpdating = true
        manager.requestLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if isAuthorized {
                lastError = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            accuracy = location.horizontalAccuracy
            timestamp = location.timestamp
            isUpdating = false
            lastError = nil
            manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            lastError = error.localizedDescription
            isUpdating = false
        }
    }
}
