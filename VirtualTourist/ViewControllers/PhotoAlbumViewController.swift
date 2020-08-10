import Foundation
import UIKit

// class PhotoAlbumViewController: UIViewController {
class PhotoAlbumViewController: UICollectionViewController {
    
    static let cellReuseIdentifier = "PhotoAlbumCell"
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
    
    var pin: Pin? = nil
    var retrivePhotoDataTask: URLSessionDataTask? = nil
    var loadPhotosTasks: [URLSessionDataTask] = []

    var loadedPhotos: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
     }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("PhotoAlbumViewController: prepare for segue")
    }

    
    func setupPhotos() {
        
        // if photos exist in the persistent store for the pin, use them.
        if let coreDataPhotos = pin!.photos, coreDataPhotos.count != 0 {
            DispatchQueue.main.async {
                self.loadedPhotos = coreDataPhotos.compactMap { photo in
                    guard let photoData = photo as? Data else {
                        return nil
                    }
                    return UIImage(data: photoData)
                    
                }
            }
        }
        else {
            retrivePhotoDataFromFlickr()
        }
    }
    
    
    private func retrivePhotoDataFromFlickr() {
        
        retrivePhotoDataTask = getFlickrPhotos(
            coordinate: pin!.coordinate
        ) { result in
            do {
                let photos = try result.get()
                self.loadPhotos(photos)
            } catch {
                print("error retrivePhotoData:\n\(error)")
            }
        }
    }
 
    private func loadPhotos(_ photos: [FlickrPhoto]) {
        loadedPhotos = []
        for photo in photos {
            let loadPhotoTask = photo.retrievePhoto { result in
                do {
                    let photo = try result.get()
                    let coreDataPhoto = Photo(context: self.managedObjectContext)
                    coreDataPhoto.pin = self.pin
                    coreDataPhoto.imageData = photo.pngData()
                    DispatchQueue.main.async {
                        self.loadedPhotos.append(photo)
                        print("appended to loadedPhotos")
                        self.collectionView.reloadData()
                        
                    }
                    
                } catch {
                    print("error getting photo:\n\(error)")
                }
            }
            loadPhotosTasks.append(loadPhotoTask)
        }
    }
    
    
    private func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
}


// MARK: - UICollectionViewDataSource -

extension PhotoAlbumViewController {
    
    override func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        print("numberOfItemsInSection:", loadedPhotos.count)
        return loadedPhotos.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.cellReuseIdentifier, for: indexPath
        ) as! PhotoAlbumCell
        
        print("getting photo for cell", indexPath.row)
        print("number of loaded photos:", loadedPhotos.count)
        cell.imageView.image = loadedPhotos[indexPath.row]
        
        print("image is nil:", cell.imageView.image == nil)
        
        return cell
        
    }
    

}
