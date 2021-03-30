//
//  LocalFileManager.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import Foundation

final class LocalFileManager {
    
    static let shared = LocalFileManager()
    
}

extension LocalFileManager {
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.first ?? NSTemporaryDirectory()
    }

    func cachesDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return paths.first ?? NSTemporaryDirectory()
    }
}

extension LocalFileManager {

    func saveData(_ data: Data, fileName: String, atPath path: String) -> Bool {
        if !FileManager.default.fileExists(atPath: path) {
            if !createNewDirectory(with: path) {
                removeFile(at: path)
            }
        }
        let newPath = NSString(string: path).appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: newPath, contents: nil, attributes: nil)
        if FileManager.default.isWritableFile(atPath: newPath) {
            do {
                try data.write(to: URL(fileURLWithPath: newPath))
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    func getData(at path: String) -> Data? {
        return FileManager.default.contents(atPath: path)
    }
    
    func createNewDirectory(with path: String) -> Bool {
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true,
                                                        attributes: nil)
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    func removeFile(at path: String) {
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                
            }
        }
    }
}
