import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    private var locationContinuation:
        CheckedContinuation<CLLocation, Error>?

    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestCurrentLocation() async throws -> CLLocation {

        guard locationContinuation == nil else {
            throw LocationError.requestAlreadyInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in

            locationContinuation = continuation

            switch manager.authorizationStatus {

            case .notDetermined:
                manager.requestWhenInUseAuthorization()

            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()

            case .denied, .restricted:
                finishWithError(LocationError.permissionDenied)

            @unknown default:
                finishWithError(LocationError.unknown)
            }
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus

        guard locationContinuation != nil else {
            return
        }

        switch manager.authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            finishWithError(LocationError.permissionDenied)

        case .notDetermined:
            break

        @unknown default:
            finishWithError(LocationError.unknown)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latestLocation = locations.last else {
            finishWithError(LocationError.locationUnavailable)
            return
        }

        location = latestLocation

        print("GPS latitude:", latestLocation.coordinate.latitude)
        print("GPS longitude:", latestLocation.coordinate.longitude)

        locationContinuation?.resume(returning: latestLocation)
        locationContinuation = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        finishWithError(error)
    }

    private func finishWithError(_ error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

enum LocationError: LocalizedError {

    case permissionDenied
    case locationUnavailable
    case requestAlreadyInProgress
    case unknown

    var errorDescription: String? {
        switch self {

        case .permissionDenied:
            return "Location permission is disabled. Please enable it in Settings."

        case .locationUnavailable:
            return "Your current location could not be determined."

        case .requestAlreadyInProgress:
            return "A location request is already in progress."

        case .unknown:
            return "An unknown location error occurred."
        }
    }
}
