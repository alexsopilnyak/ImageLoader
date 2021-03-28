
import UIKit
import NetworkService

//MARK: Typealias
public typealias ImageHandler = (_ image: UIImage?, _ url: URL, _ indexPath: IndexPath?, _ error: Error?) -> ()
public typealias CompletionHandler = (_ image: UIImage?, _ indexPath: IndexPath?, _ error: Error?) -> ()


//MARK: Protocol
public protocol ImageProvider {
    func downloadImage(from url: String, indexPath: IndexPath?, completion: @escaping CompletionHandler)
    func cancellAllDownloads()
}

//MARK: ImageLoader
public final class ImageLoader: ImageProvider {
    
    private let cache = NSCache<NSString, UIImage>()
    private let networkService = NetworkService()
    
    private lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.imageLoader.downloadQueue"
        queue.qualityOfService = .userInteractive
        
        return queue
    }()
    
    
    public func downloadImage(from url: String, indexPath: IndexPath?, completion: @escaping CompletionHandler) {
        
        guard let url = URL(string: url) else {
            completion(nil, nil, LoaderError.badURL)
            return
        }
        
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            completion(cachedImage, indexPath, nil)
        } else {
                let downloadOperation = DownloadOperation(networkService: networkService, imageURL: url, indexPath: indexPath)

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
    
    public func cancellAllDownloads() {
        downloadQueue.cancelAllOperations()
    }
    
}


