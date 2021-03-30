//
//  AppDateFormatter.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import Foundation

enum DateFormat: String {
    case fullTimeFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    case record = "MMM dd, HH:mm:ss"
}

struct AppDateFormatter {
    
    static var fullTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = DateFormat.fullTimeFormat.rawValue
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }
    
    static var recordFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.record.rawValue
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }
}
