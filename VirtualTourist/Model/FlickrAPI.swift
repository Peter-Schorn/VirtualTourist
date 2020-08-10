import Foundation
import MapKit


/// Retrieves flickr photos for the specified coordinates.
func getFlickrPhotos(
    coordinate: CLLocationCoordinate2D,
    completion: @escaping (Result<[FlickrPhoto], Error>) -> Void
) -> URLSessionDataTask {

    var endpoint = URLComponents()
    endpoint.scheme = "https"
    endpoint.host = "www.flickr.com"
    endpoint.path = "/services/rest/"
    endpoint.queryItems = [
        .init(name: "method", value: "flickr.photos.search"),
        .init(name: "api_key", value: "90713d03c8586f7e6f11aede6b8fa6bb"),
        .init(name: "lat", value: "\(coordinate.latitude)"),
        .init(name: "lon", value: "\(coordinate.longitude)"),
        .init(name: "per_page", value: "30"),
        .init(name: "format", value: "json"),
        .init(name: "nojsoncallback", value: "1")
    ]

    debugPrint("url:", endpoint.url!)
    
    let task = URLSession.shared.dataTask(with: endpoint.url!) {
        data, urlResponse, error in
        
        guard let data = data else {
            
            completion(.failure(error ?? NSError()))
            return
        }
        do {
            let stringData = String(data: data, encoding: .utf8)!
            print("\n\n" + stringData + "\n")
            
            
            let photos = try JSONDecoder().decode(
                FlickrPhotosArray.self, from: data
            )
            print("retrieved \(photos.photos.count) photos")
            completion(.success(photos.photos))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
    return task
    
}



