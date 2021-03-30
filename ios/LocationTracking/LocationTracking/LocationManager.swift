//
//  LocationManager.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import Foundation
import CoreLocation

enum LocationStatus: Codable {
    case online
    case deviceOff
    case userOffline
    case disable
    case disallowed
    
    enum RawValue: String, Codable {
        case online = "Online"
        case deviceOff = "Device off"
        case userOffline = "User offline"
        case disable = "Disable"
        case disallowed = "Disallowed"
    }
    
    init?(rawValue: String?) {
        if let rawValue = rawValue,
            let value = RawValue(rawValue: rawValue) {
            switch value {
            case .online:
                self = .online
            case .deviceOff:
                self = .deviceOff
            case .userOffline:
                self = .userOffline
            case .disable:
                self = .disable
            case .disallowed:
                self = .disallowed
            }
        } else {
            self = .disallowed
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        if let value = RawValue(rawValue: decodedString) {
            switch value {
            case .online:
                self = .online
            case .deviceOff:
                self = .deviceOff
            case .userOffline:
                self = .userOffline
            case .disable:
                self = .disable
            case .disallowed:
                self = .disallowed
            }
        } else {
            self = .disallowed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .online:
            try container.encode(RawValue.online)
        case .deviceOff:
            try container.encode(RawValue.deviceOff)
        case .userOffline:
            try container.encode(RawValue.userOffline)
        case .disable:
            try container.encode(RawValue.disable)
        case .disallowed:
            try container.encode(RawValue.disallowed)
        }
    }
    
    var value: String {
        switch self {
        case .online:
        return RawValue.online.rawValue
        case .deviceOff:
        return RawValue.deviceOff.rawValue
        case .userOffline:
        return RawValue.userOffline.rawValue
        case .disable:
        return RawValue.disable.rawValue
        case .disallowed:
        return RawValue.disallowed.rawValue
        }
    }
}
    
final class LocationManager: NSObject {
    
    static let shared = LocationManager()
    
    var locationManager = CLLocationManager()
    
    private var trackLocationTimer: Timer?
    
    private var lastestValidLocationLocation: CLLocation?
    private var lastestInvalidLocationData: LocationData?
    private var isLocationValid: Bool = false
    
    struct Constants {
        static let trackLocationInterval: TimeInterval = 15.0
        static let minLocationAccuracyInMeter: TimeInterval = 50.0
    }

    func configure() {
        
        DispatchQueue.main.async { [weak self] in
            self?.locationManager = CLLocationManager()
            self?.locationManager.delegate = self
            self?.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self?.locationManager.requestAlwaysAuthorization()
            self?.locationManager.allowsBackgroundLocationUpdates = true
            self?.locationManager.distanceFilter = 10
            self?.locationManager.pausesLocationUpdatesAutomatically = false
            self?.locationManager.activityType = .automotiveNavigation
            self?.startUpdatingLocation()
        }
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            print("Location Services are unavailable, please check it in Settings or related places.")
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied, .notDetermined, .restricted:
            self.lastestValidLocationLocation = nil
        default:
            handleTrackCurrentUserLocation()
            break
        }
    }
}

// MARK: - Location Services State
extension LocationManager {
    
    func getLocationStatus(coordinate: CLLocationCoordinate2D?) -> LocationStatus {
        if let _  = coordinate {
            return .online
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .denied:
            return .disable
        case .notDetermined:
            return .disallowed
        default: break
        }
        return .userOffline
        
    }
}

// MARK: - Tracking Current LocationData
extension LocationManager {
    
    func startTrackLocationTimer() {
        stopTrackLocationTimer()
        trackLocationTimer = Timer.scheduledTimer(timeInterval: Constants.trackLocationInterval,
                                                 target: self,
                                                 selector: #selector(handleTrackCurrentUserLocation),
                                                 userInfo: nil, repeats: true)
    }
    
    fileprivate func stopTrackLocationTimer() {
        trackLocationTimer?.invalidate()
        trackLocationTimer = nil
    }
    
    @objc fileprivate func handleTrackCurrentUserLocation() {
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        
        // 2. Get current Location data
        let currentLocationData = createCurrentLocationData(isUserOffline: false)
        
        // 3. Save to local
        saveCurrentLocationDataToLocal(currentLocationData)
        
        var datas = LocalDataManager.shared.getListLocationData()
        guard !datas.isEmpty else {
            return
        }
        
        if isLocationValid,
            let lastestInvalidLocationData = lastestInvalidLocationData {
            datas.append(lastestInvalidLocationData)
        }
        LocalDataManager.shared.saveListLocationDatas(datas)
        //Post locations
        NotificationCenter.default.post(name: .newUserLocation, object: nil, userInfo: nil)
    }
    
    func performSaveUserOfflineWhenKillApp() {
        let currentLocationData = createCurrentLocationData(isUserOffline: true)
        saveCurrentLocationDataToLocal(currentLocationData)
    }
    
    func performSyncDisableLocationWhenAppDidEnterBackground() {
        let currentLocationData = createDisableLocationData()
        saveCurrentLocationDataToLocal(currentLocationData)
        var datas = LocalDataManager.shared.getListLocationData()
        guard !datas.isEmpty else {
            return
        }
        
        if isLocationValid,
            let lastestInvalidLocationData = lastestInvalidLocationData {
            datas.append(lastestInvalidLocationData)
        }
        LocalDataManager.shared.saveListLocationDatas(datas)
        
        //Post locations
        NotificationCenter.default.post(name: .newUserLocation, object: nil, userInfo: nil)
    }
    
    private func createCurrentLocationData(isUserOffline: Bool) -> LocationData {
        refreshLastestLocationValues()
        let currentTime = AppDateFormatter.fullTimeFormatter.string(from: Date())
        let status = isUserOffline ? LocationStatus.userOffline :
            LocationManager.shared.getLocationStatus(coordinate: lastestValidLocationLocation?.coordinate)
        if let locationCoordinate = self.lastestValidLocationLocation?.coordinate {
            let data = LocationData(lat: locationCoordinate.latitude,
                                  lng: locationCoordinate.longitude,
                                  time: currentTime,
                                  status: status)
            return data
        } else {
            let data = LocationData(lat: nil,
                                  lng: nil,
                                  time: currentTime,
                                  status: status)
            return data
        }
    }
    
    private func createInvalidLocationData(_ coodinator: CLLocationCoordinate2D) -> LocationData {
        refreshLastestLocationValues()
        let currentTime = AppDateFormatter.fullTimeFormatter.string(from: Date())
        let status = LocationManager.shared.getLocationStatus(coordinate: coodinator)
        let data = LocationData(lat: coodinator.latitude,
                              lng: coodinator.longitude,
                              time: currentTime,
                              status: status)
        return data
    }
    
    private func createDisableLocationData() -> LocationData {
        refreshLastestLocationValues()
        let currentTime = AppDateFormatter.fullTimeFormatter.string(from: Date())
        let status = LocationStatus.disable
        let data = LocationData(lat: nil,
                              lng: nil,
                              time: currentTime,
                              status: status)
        return data
    }
    
    fileprivate func refreshLastestLocationValues() {
        guard let currentLocation = locationManager.location else {
            return
        }
        print("===============")
        print(currentLocation)
        print("VerticalAccuracy is: \(currentLocation.verticalAccuracy)")
        print("===============")
        
        guard let _ = lastestValidLocationLocation else {
            self.lastestValidLocationLocation = currentLocation
            return
        }

        let currentVerticalAccuracy = Double(currentLocation.verticalAccuracy)
        let validAccuracy = Constants.minLocationAccuracyInMeter
        
        if currentVerticalAccuracy > validAccuracy { // invalid
            isLocationValid = false
            self.lastestInvalidLocationData = createInvalidLocationData(currentLocation.coordinate)
        } else {
            isLocationValid = true
            self.lastestValidLocationLocation = currentLocation
        }
    }
    
    private func saveCurrentLocationDataToLocal(_ data: LocationData) {
        LocalDataManager.shared.saveNewLocationData(data)
    }
}

extension  NSNotification.Name {
    static let newUserLocation = NSNotification.Name(rawValue: "Tracking new user location")
}
