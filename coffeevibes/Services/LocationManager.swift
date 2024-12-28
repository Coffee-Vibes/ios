import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        
        // Request authorization immediately if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy > 0 else { return }
        
        DispatchQueue.main.async {
            // Always update on first location
            if self.currentLocation == nil {
                self.currentLocation = location
            }
            // Then only update if we've moved significantly
            else if location.distance(from: self.currentLocation!) > 50 {
                self.currentLocation = location
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func calculateDistance(to shopLocation: CLLocation) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        let distanceInMeters = currentLocation.distance(from: shopLocation)
        return distanceInMeters * 0.000621371 // Convert meters to miles
    }
    
    func requestLocation() {
        // Check authorization and request if needed
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Stop updates first to ensure we get a fresh location
            locationManager.stopUpdatingLocation()
            // Then start updating again
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
} 