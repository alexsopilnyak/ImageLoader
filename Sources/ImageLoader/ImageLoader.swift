
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
    
    private let networkProvider: NetworkProvider
    
    private lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.imageLoader.downloadQueue"
        queue.qualityOfService = .userInteractive
        
        return queue
    }()
    
    public init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    public func downloadImage(from url: String, indexPath: IndexPath?, completion: @escaping CompletionHandler) {
        
        guard let url = URL(string: url) else {
            completion(nil, nil, LoaderError.badURL)
            return
        }
        
        if let cachedImage = ImageCache.instance.readImageForKey(key: url.absoluteString) {
            
            completion(cachedImage, indexPath, nil)
            
            print("GET FROM CACHE --- \(url.absoluteString)")
            
        } else {
            print("NEW DOWNLOAD --- \(url.absoluteString)")
            let downloadOperation = DownloadOperation(networkService: networkProvider, imageURL: url, indexPath: indexPath)
            
            if indexPath == nil {
                downloadOperation.queuePriority = .high
            }
            
            downloadOperation.downloadHandler = { image, url, indexPath, error in
                if let newImage = image {
                    ImageCache.instance.write(image: newImage, forKey: url.absoluteString)
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


