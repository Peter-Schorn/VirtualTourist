import Foundation
import UIKit

struct FlickrPhoto: Codable, Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.imageURL == rhs.imageURL
    }
    
    
    let id: String
    let owner: String?
    let secret: String
    let server: String
    let farm: Int
    let title: String?
    let ispublic: Int?
    let isfriend: Int?
    let isfamily: Int?
    
    var imageURL: URL {
        return URL(string:
            "https://farm\(farm).staticflickr.com/" +
            "\(server)/\(id)_\(secret).jpg"
        )!
    }
    
    @discardableResult
    func retrievePhoto(
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) -> URLSessionDataTask {
        
        let task = URLSession.shared.dataTask(with: imageURL) {
            data, urlResponse, error in
            
            guard let data = data,
                    let image = UIImage(data: data)
            else {
                completion(.failure(error ?? NSError()))
                return
            }
            
            completion(.success(image))
        }
        task.resume()
        return task
        
    }
    
}


struct FlickrPhotosData: Decodable {
    
    let photos: [FlickrPhoto]
    let totalPages: Int
    
    init(from decoder: Decoder) throws {
        let topLevelContainer = try decoder.container(
            keyedBy: TopLevelKeys.self
        )
        let photosDataContainer = try topLevelContainer.nestedContainer(
            keyedBy: PhotosKeys.self,
            forKey: .photos
        )
        
        self.photos = try photosDataContainer.decode(
            [FlickrPhoto].self, forKey: .photo
        )
        
        let putativeTotalPages = try photosDataContainer.decode(
            Int.self, forKey: .totalPages
        )
        self.totalPages = min(putativeTotalPages, 100)
        
    }
    
    enum TopLevelKeys: String, CodingKey {
        case photos, stat
    }
    
    enum PhotosKeys: String, CodingKey {
        case page
        case totalPages = "pages"
        case perpage
        case totalPhotos = "total"
        case photo
    }
    
}
