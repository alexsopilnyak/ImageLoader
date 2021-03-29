//
//  ImageCache.swift
//  ImageLoadService
//
//  Created by Alexandr Sopilnyak on 29.03.2021.
//

import UIKit

public enum ImageFormat {
    case unknown, png, jpeg
}

public final class ImageCache {
    
    static let cacheDirectoryPrefix = "com.nch.cache."
    static let ioQueuePrefix = "com.nch.queue."
    static let defaultMaxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7         // a week
    
    public static var instance = ImageCache(name: "default")
    
    var cachePath: String
    
    let memCache = NSCache<AnyObject, AnyObject>()
    let ioQueue: DispatchQueue
    let fileManager: FileManager
    
    public var name: String = ""
    
    public var maxCachePeriodInSecond = ImageCache.defaultMaxCachePeriodInSecond
    
    public var maxDiskCacheSize: UInt = 0
    
    public init(name: String, path: String? = nil) {
        self.name = name
        
        cachePath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        cachePath = (cachePath as NSString).appendingPathComponent(ImageCache.cacheDirectoryPrefix + name)
        
        ioQueue = DispatchQueue(label: ImageCache.ioQueuePrefix + name)
        
        self.fileManager = FileManager()
        
    }
    
    // MARK: Read/write image
    
    public func write(image: UIImage, forKey key: String, format: ImageFormat? = nil) {
        var data: Data? = nil
        
//        if let format = format, format == .png {
//            data = image.da
//        }
//        else {
//            data = image.jpegData(compressionQuality: 0.9)
//        }
        
        data = image.pngData()
        
        if let data = data {
            write(data: data, forKey: key)
        }
    }
    
    
    public func readImageForKey(key: String) -> UIImage? {
        let data = readData(forKey: key)
        if let data = data {
            return UIImage(data: data, scale: 1.0)
        }
        
        return nil
    }
    
    // MARK: Clean memory
    public func cleanDiskCache() {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.cachePath)
            } catch {}
        }
    }
    
    public func cleanMemCache() {
            memCache.removeAllObjects()
        }
    
    // MARK: Write
    
    private func write(data: Data, forKey key: String) {
        memCache.setObject(data as AnyObject, forKey: key as AnyObject)
        writeDataToDisk(data: data, key: key)
    }
    
    private func writeDataToDisk(data: Data, key: String) {
        ioQueue.async {
            if self.fileManager.fileExists(atPath: self.cachePath) == false {
                do {
                    try self.fileManager.createDirectory(atPath: self.cachePath, withIntermediateDirectories: true, attributes: nil)
                }
                catch {
                    print("Error while creating cache folder")
                }
            }
            print("Write data to disk for key \(key)")
            self.fileManager.createFile(atPath: self.cachePath(forKey: key), contents: data, attributes: nil)
        }
    }
    
    // MARK: Read
    
    private func readData(forKey key:String) -> Data? {
        var data = memCache.object(forKey: key as AnyObject) as? Data
        
        if data == nil {
            if let dataFromDisk = readDataFromDisk(forKey: key) {
                data = dataFromDisk
                memCache.setObject(dataFromDisk as AnyObject, forKey: key as AnyObject)
            }
        }
        print("Read data from disk for key: \(key)")
        return data
    }
    
    private func readDataFromDisk(forKey key: String) -> Data? {
        return self.fileManager.contents(atPath: cachePath(forKey: key))
    }
    
    private func cachePath(forKey key: String) -> String {
        let fileName = key.md5
        return (cachePath as NSString).appendingPathComponent(fileName)
    }
}

