//
//  LocalDataManager.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import Foundation
import UIKit

final class LocalDataManager {
    
    static let shared = LocalDataManager()
    
    func clearAllLocalData() {
        removeAllListLocalLocationData()
    }
}

// MARK: - Location Data
extension LocalDataManager {
    
    func saveNewLocationData(_ data: LocationData) {
        var savedDatas: [LocationData] = getListLocationData()
        savedDatas.insert(data, at: 0)
        saveListLocationDatas(savedDatas)
    }
    
    func saveListLocationDatas(_ datas: [LocationData]) {
        do {
            let data = try PropertyListEncoder().encode(datas)
            let path = getLocationDataDirectoryName()
            let fileName = "location_tracking"
            let success = LocalFileManager.shared.saveData(data, fileName: fileName, atPath: path)
            if success {
                print("Save GPS Data successful")
            } else {
                print("Save GPS Data failed")
            }
        } catch {
            print("Save GPS Data failed")
        }
    }
    
    
    func getListLocationData() -> [LocationData] {
        let path = getLocationDataFileName()
        guard let savedData = LocalFileManager.shared.getData(at: path) else {
            return []
        }
        do {
            let locationData = try PropertyListDecoder().decode([LocationData].self, from: savedData)
            return locationData
        } catch {
            return []
        }
    }
    
    func removeAllListLocalLocationData() {
        let path = getLocationDataFileName()
        LocalFileManager.shared.removeFile(at: path)
    }
    
    fileprivate func getLocationDataFileName() -> String {
        let folderPath = getLocationDataDirectoryName()
        return NSString(string: folderPath).appendingPathComponent("location_tracking")
    }
    
    fileprivate func getLocationDataDirectoryName() -> String {
        let documentPath = LocalFileManager.shared.documentsDirectory()
        return NSString(string: documentPath).appendingPathComponent("location")
    }

}
