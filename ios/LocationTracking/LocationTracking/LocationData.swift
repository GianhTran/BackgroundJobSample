//
//  LocationData.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import Foundation
import ObjectMapper

struct LocationData {
    
    var lat: Double?
    var lng: Double?
    var time: String
    var status: LocationStatus
    
}

extension LocationData {
    init() {
        lat = nil
        lng = nil
        time = ""
        status = .online
    }
}

extension LocationData: Mappable {
    
    init?(map: Map) {
        self.init()
    }
    
    mutating func mapping(map: Map) {
        lat <- map["lat"]
        lng <- map["lng"]
        time <- map["time"]
        status = LocationStatus(rawValue: map.JSON["status"] as? String) ?? .disallowed
    }
}

// MARK: - Codable
extension LocationData: Codable {
    
    enum Key: String, CodingKey {
        case lat, lng, time, status
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: Key.self)
        if let lat = try? container.decode(Double.self, forKey: Key.lat) {
            self.lat = lat
        }
        if let lng = try? container.decode(Double.self, forKey: Key.lng) {
            self.lng = lng
        }
        if let time = try? container.decode(String.self, forKey: Key.time) {
            self.time = time
        }
        if let status = try? container.decode(LocationStatus.self, forKey: Key.status) {
            self.status = status
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(lat, forKey: Key.lat)
        try container.encode(lng, forKey: Key.lng)
        try container.encode(time, forKey: Key.time)
        try container.encode(status, forKey: Key.status)
    }
}

extension LocationData {
    
    var locationDisplay: String {
        return String(format: "%.6f, %.6f", lat ?? 0.0, lng ?? 0.0)
    }
    
    var timeDisplay: String {
        guard let date = AppDateFormatter.fullTimeFormatter.date(from: time) else {
            return ""
            
        }
        return AppDateFormatter.recordFormatter.string(from: date)
    }
    
    var lastLocationDisplay: String {
        return String(format: "Last location: %@", locationDisplay)
    }
    
    var lastTimeDisplay: String {
        return String(format: "Last time: %@", timeDisplay)
    }
}
