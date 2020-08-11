import Foundation
import MapKit

private var flickrPhotosDict: [CLLocationCoordinate2D: ([FlickrPhoto], page: Int)] = [:]


/// Retrieves flickr photos for the specified coordinates.
func getFlickrPhotos(
    coordinate: CLLocationCoordinate2D,
    page: Int,
    completion: @escaping (Result<FlickrPhotosData, Error>) -> Void
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
        .init(name: "page", value: "\(page)"),
        .init(name: "format", value: "json"),
        .init(name: "nojsoncallback", value: "1")
    ]

    // debugPrint("getFlickrPhotos url:", endpoint.url!)
    
    let task = URLSession.shared.dataTask(with: endpoint.url!) {
        data, urlResponse, error in
        
        guard let data = data else {
            
            completion(.failure(error ?? NSError()))
            return
        }
        let stringData = String(data: data, encoding: .utf8)!
        
        do {
            
            // print(stringData)
            
            let photosArray = try JSONDecoder().decode(
                FlickrPhotosData.self, from: data
            )
            print("getFlickrPhotos: retrieved \(photosArray.photos.count) photos")
            
            
            
            if let previousPhotos = flickrPhotosDict[coordinate] {
                if previousPhotos.page != page {
                    for photo in previousPhotos.0 {
                        if photosArray.photos.contains(photo) {
                            print(
                                "\n\nflickr api returned duplicate photos for different pages\n\n"
                            )
                            
                        }
                    }
                }
            }
            var current = flickrPhotosDict[coordinate] ?? ([], page: page)
            current.0.append(contentsOf: photosArray.photos)
            flickrPhotosDict[coordinate] = current
                
            
            
            completion(.success(photosArray))
            
        } catch {
            print("\n" + stringData + "\n")
            completion(.failure(error))
        }
    }
    
    task.resume()
    return task
    
}



