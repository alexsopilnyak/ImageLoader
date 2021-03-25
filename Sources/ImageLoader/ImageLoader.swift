
import UIKit
import NetworkService


public typealias ImageHandler = (_ image: UIImage?, _ url: URL, _ indexPath: IndexPath?, _ error: Error?) -> ()
public typealias CompletionHandler = (_ image: UIImage?, _ indexPath: IndexPath?, _ error: Error?) -> ()

public protocol ImageProvider {
    func downloadImage(from url: URL, indexPath: IndexPath?, completion: @escaping CompletionHandler)
    func cancellAllDownloads()
}

public final class ImageLoader: ImageProvider {
    public static let shared = ImageLoader()
    
    private let cache = NSCache<NSString, UIImage>()
    private let networkService = NetworkService()
    
    private lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.imageLoader.downloadQueue"
        queue.qualityOfService = .userInteractive
        
        return queue
    }()
    
    private init() {}
    
    public func downloadImage(from url: URL, indexPath: IndexPath?, completion: @escaping CompletionHandler) {
        
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            print("Return cached Image for \(url)")
            completion(cachedImage, indexPath, nil)
        } else {
            if let operations = (downloadQueue.operations as? [DownloadOperation])?.filter({ $0.imageURL.absoluteString == url.absoluteString && $0.isFinished == false && $0.isExecuting == true}),
               let operation = operations.first {
                
                print("Increase the priority for \(url)")
                operation.queuePriority = .veryHigh
            } else {
                let downloadOperation = DownloadOperation(networkService: networkService, imageURL: url, indexPath: indexPath)
                print("Create a new task for \(url)")
                
                if indexPath == nil {
                    downloadOperation.queuePriority = .high
                }
                
                downloadOperation.downloadHandler = { image, url, indexPath, error in
                    if let newImage = image {
                        self.cache.setObject(newImage, forKey: url.absoluteString as NSString)
                    }
                    completion(image, indexPath, error)
                }
                downloadQueue.addOperation(downloadOperation)
            }
        }
    }
    
    public func cancellAllDownloads() {
        downloadQueue.cancelAllOperations()
    }
    
}

