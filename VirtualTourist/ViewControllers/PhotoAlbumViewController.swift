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
    
    override func viewWillDisappear(_ animated: Bool) {
        print("view will disappear")
        saveContext()
    }
    

    func displayNoImagesLabel() {
        DispatchQueue.main.async {
            
            print("displayNoImagesLabel")
            let label = UILabel()
            label.frame = CGRect(
                x: 0, y: 0,
                width: self.view.frame.width - 50,
                height: 100
            )
            label.center = self.view.center
            label.textAlignment = .center
            label.text = "No Images Found"
            label.font = .boldSystemFont(ofSize: 40)
            label.adjustsFontSizeToFitWidth = true
            self.view.addSubview(label)
            
        }
    }

    
    func setupPhotos() {
        
        // if photos exist in the persistent store for the pin, use them.
        if let coreDataPhotos = pin!.photos, coreDataPhotos.count != 0 {
            print("found photos in coredata")
            
                loadedPhotos = []
                for photo in coreDataPhotos {

                    guard let photo = photo as? Photo,
                            let imageData = photo.imageData,
                            let uiImage = UIImage(data: imageData)
                    else {
                        print("couldn't get image from CoreData")
                        continue
                    }
                    
                    DispatchQueue.main.async {
                        self.loadedPhotos.append(uiImage)
                        self.collectionView.reloadData()
                    }
                }
                
        }
        // else, retrieve photos from flickr.
        else {
            print("retrivePhotoDataFromFlickr")
            retrivePhotoDataFromFlickr()
        }
    }
    
    
    private func retrivePhotoDataFromFlickr() {
        
        retrivePhotoDataTask = getFlickrPhotos(
            coordinate: pin!.coordinate
        ) { result in
            do {
                let photos = try result.get()
                if photos.isEmpty {
                    self.displayNoImagesLabel()
                }
                else {
                    self.loadPhotos(photos)
                }
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
        // print("numberOfItemsInSection:", loadedPhotos.count)
        return loadedPhotos.count
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.cellReuseIdentifier, for: indexPath
        ) as! PhotoAlbumCell
        
        // print("getting photo for cell", indexPath.row)
        cell.imageView.image = loadedPhotos[indexPath.row]
        
        return cell
        
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        
        

    }
    

}


extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        // print("configure size")
        let length = view.frame.width / 3 - 20
        return CGSize(width: length, height: length)

    }

}
