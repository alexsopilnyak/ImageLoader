import UIKit
import NetworkService

final class DownloadOperation: Operation {
    var downloadHandler: ImageHandler?
    var imageURL: URL!
    private var indexPath: IndexPath?
    private let networkService: NetworkProvider
    
    override var isAsynchronous: Bool {
        get {
            return  true
        }
    }
    
    override var isExecuting: Bool {
        _isExecuting
    }
    
    override var isFinished: Bool {
        _isFinished
    }
    
    private var _isExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    func executing(_ executing: Bool) {
        _isExecuting = executing
    }
    
    func finished(_ finished: Bool) {
        _isFinished = finished
    }
    
    required init(networkService: NetworkProvider, imageURL: URL, indexPath: IndexPath?) {
        self.networkService = networkService
        self.imageURL = imageURL
        self.indexPath = indexPath
    }
    
    override func main() {
        guard  isCancelled == false  else {
            finished(true)
            return
        }
            executing(true)
            self.loadImageFromURL()
    }
    
    private func loadImageFromURL() {
        let resource = Resource(method: .get, url: imageURL)
        networkService.performRequest(for: resource) { result in
    
            switch result {
            case .failure(let error):
                self.downloadHandler?(nil, self.imageURL, nil, error)
                self.finished(false)
                self.executing(false)
                
            case .success(let data):
                let image = UIImage(data: data)
                
                self.downloadHandler?(image, self.imageURL, self.indexPath, nil)
                self.finished(true)
                self.executing(false)
                
            }
        }
    }
}

