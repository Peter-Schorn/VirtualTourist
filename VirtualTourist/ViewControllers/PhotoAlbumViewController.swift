import Foundation
import UIKit

// class PhotoAlbumViewController: UIViewController {
class PhotoAlbumViewController: UICollectionViewController {
    
    static let cellReuseIdentifier = "PhotoAlbumCell"
    
    var pin: Pin? = nil
    var retrivePhotoDataTask: URLSessionDataTask? = nil
    var loadPhotoImagesTask: URLSessionDataTask? = nil

    var loadedPhotos: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("PhotoAlbumViewController: prepare for segue")
        retrivePhotoData()
    }

    
    func retrivePhotoData() {
        
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
            photo.retrievePhoto { result in
                do {
                    let photo = try result.get()
                    DispatchQueue.main.async {
                        self.loadedPhotos.append(photo)
                        print("appended to loadedPhotos")
                        
                        self.collectionView.reloadData()
                    }
                    
                } catch {
                    print("error getting photo:\n\(error)")
                }
            }
        }
    }
    
    
}


// MARK: UICollectionViewDataSource
extension PhotoAlbumViewController {
    
    override func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 0
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return loadedPhotos.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.cellReuseIdentifier, for: indexPath
        ) as! PhotoCell
        
        print("getting photo for cell")
        cell.imageView.image = loadedPhotos[indexPath.row]
        
        return cell
        
    }
    

}
