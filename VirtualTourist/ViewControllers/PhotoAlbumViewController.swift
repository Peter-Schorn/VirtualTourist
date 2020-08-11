import Foundation
import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    static let cellReuseIdentifier = "PhotoAlbumCell"
    
    // MARK: IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
    
    var pin: Pin? = nil
    
    var totalFlickrPhotosPages = 0
    
    var retreivePhotoDataTask: URLSessionDataTask? = nil
    var loadPhotosTasks: [URLSessionDataTask] = []

    var fetchedResultsController: NSFetchedResultsController<Photo>? = nil
    
    var collectionViewCells: [PhotoAlbumCell] = [] {
        didSet {
            print(
                "didSet collectionViewCells:\n" +
                "old count: \(oldValue.count), " +
                "new count: \(collectionViewCells.count)"
            )
        }
    }
    
    var isDownloadingImages = false {
        didSet {
            DispatchQueue.main.async {
                self.newCollectionButton.isEnabled =
                        !self.isDownloadingImages
            }
        }
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        print("tapped new collection button")
        
        collectionViewCells = []
        collectionView.reloadData()
        
        retreivePhotoDataTask?.cancel()
        retreivePhotoDataTask = nil
        for task in loadPhotosTasks {
            task.cancel()
        }
        loadPhotosTasks = []
        
        let lowerBound = min(totalFlickrPhotosPages, 2)
        // let upperBound = max(totalFlickrPhotosPages, 100)
        
        let upperBound = totalFlickrPhotosPages
        
        let newPage = Int.random(
            in: lowerBound...upperBound
        )
        
        print("getting Flickr photos for page", newPage)
        
        activityIndicator.startAnimating()
        isDownloadingImages = true
        retrievePhotoDataFromFlickr(page: newPage)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("view will disappear")
        saveContext()
    }
    
    func displayNoImagesLabel() {
        DispatchQueue.main.async {
            
            print("displayNoImagesLabel")
            self.activityIndicator.stopAnimating()
            self.isDownloadingImages = false
            let label = UILabel()
            label.frame = CGRect(
                x: 0, y: 0,
                width: self.view.frame.width - 50,
                height: 100
            )
            label.center = self.view.center
            label.textAlignment = .center
            label.text = "No Images Found"
            label.textColor = .secondaryLabel
            label.font = .boldSystemFont(ofSize: 40)
            label.adjustsFontSizeToFitWidth = true
            self.view.addSubview(label)
            self.newCollectionButton.isHidden = true
            
        }
    }

    func setupFetchedResultsController() {
        
        guard let pin = pin else {
            fatalError("setupPhotos: pin is nil")
        }
        
        let fetchRequest: NSFetchRequest = Photo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        self.fetchedResultsController = .init(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        do {
            try fetchedResultsController!.performFetch()
            
        } catch {
            print("fetchedResultsController couldn't fetch images")
        }

    }
    
    // MARK: Entry Point
    func setupPhotos() {
       
        self.loadViewIfNeeded()
        
        assert(collectionView != nil, "collection view is nil")
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        isDownloadingImages = true
        
        setupFetchedResultsController()

        // try to get photos associated with pin from core data
        let coreDataPhotos = fetchedResultsController?.fetchedObjects
        
        if let coreDataPhotos = coreDataPhotos, !coreDataPhotos.isEmpty {
            print(
                "setupPhotos: found \(coreDataPhotos.count) " +
                "photos in core data"
            )
            
            activityIndicator.stopAnimating()
            for (indx, photo) in coreDataPhotos.enumerated() {

                
                guard let uiImage = photo.imageData
                        .map(UIImage.init(data:)) as? UIImage
                else {
                    continue
                }
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: Self.cellReuseIdentifier,
                    for: IndexPath(row: indx, section: 1)
                ) as! PhotoAlbumCell
                
                cell.configure()
                cell.imageView.image = uiImage
                cell.id = photo.id
                collectionViewCells.append(cell)
                collectionView.reloadData()
            }
            isDownloadingImages = false
            return
        }
        
      
        // if no photos were found in core data, then retrieve photos
        // from Flickr.
        print("setupPhotos: retreiving photo data from Flickr")
        retrievePhotoDataFromFlickr(page: 0)
      
    }
    
    
    private func retrievePhotoDataFromFlickr(page: Int) {
        
        retreivePhotoDataTask = getFlickrPhotos(
            coordinate: pin!.coordinate,
            page: page
        ) { result in
            do {
                let photosData = try result.get()
                let photos = photosData.photos
                self.totalFlickrPhotosPages = photosData.totalPages
                if photos.isEmpty {
                    print("retrievePhotoDataFromFlickr: no photos found")
                    self.displayNoImagesLabel()
                }
                else {
                    print(
                        "retrievePhotoDataFromFlickr: " +
                        "retrieved \(photos.count) photos"
                    )
                    DispatchQueue.main.async {
                        self.loadPhotos(photos)
                    }
                    
                }
            } catch {
                self.displayNoImagesLabel()
                print("retrievePhotoDataFromFlickr error:\n\(error)")
            }
        }
    }

    private func loadPhotos(_ flickrPhotos: [FlickrPhoto]) {

        print("func loadPhotos")
        
        activityIndicator.stopAnimating()
        
        /// Techinally, this is the number of photos that
        /// either loaded or couldn't be loaded because
        /// of an error.
        var numberOfloadedPhotos = 0
        
        for (indx, flickrPhoto) in flickrPhotos.enumerated() {
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.cellReuseIdentifier,
                for: IndexPath(row: indx, section: 1)
            ) as! PhotoAlbumCell
            
            cell.configure()
            cell.activityIndicator.startAnimating()
            
            let task = flickrPhoto.retrievePhoto { result in
                do {
                    
                    // ensure that this block gets executed even
                    // if an error is thrown
                    defer {
                        DispatchQueue.main.async {
                            cell.activityIndicator.stopAnimating()
                            numberOfloadedPhotos += 1
                            
                            if numberOfloadedPhotos == flickrPhotos.count {
                                // then all of the photos have finished downloading,
                                // or at least an attempt has been made to
                                // download them.
                                self.isDownloadingImages = false
                                print("\n\nfinished downloading all photos\n\n")
                            }
                                
                        }
                    }
                    
                    let photo = try result.get()
                    let newCoreDataPhoto = Photo(
                        context: self.managedObjectContext
                    )
                    newCoreDataPhoto.pin = self.pin!
                    newCoreDataPhoto.imageData = photo.pngData()!
                    DispatchQueue.main.async {
                        // print(
                        //     "loadPhotos: finished loading photo " +
                        //     "for cell", indx
                        // )
                        cell.imageView.image = photo
                        cell.id = newCoreDataPhoto.id
                    }
                    
                } catch {
                    
                    let nsError = error as NSError
                        
                    if nsError.code == NSURLErrorCancelled {
                        print(
                            "user cancelled loading photo for cell",
                            indx
                        )
                        return
                    }
                    
                    DispatchQueue.main.async {
                        cell.couldntLoadImageLabel.isHidden = false
                    }
                    print("loadPhotos: error retreiving flickr photo:\n\(error)")
                }
            }
            loadPhotosTasks.append(task)
            collectionViewCells.append(cell)
            collectionView.reloadData()
        }
        
        if collectionViewCells.isEmpty {
            DispatchQueue.main.async {
                self.displayNoImagesLabel()
            }
        }
        
    }
    
    
    
    private func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    
}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        
        let number = collectionViewCells.count
        
        // print("numberOfItemsInSection:", number)
        return number
        
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        
        return collectionViewCells[indexPath.row]
    
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        
        print("collectionView didSelectItemAt:", indexPath.row)
        
        
        // cancel the photo download task for the cell that is
        // being removed.
        if loadPhotosTasks.indices.contains(indexPath.row) {
            let removedTask = loadPhotosTasks.remove(at: indexPath.row)
            removedTask.cancel()
        }
        
        let removedCell = collectionViewCells.remove(at: indexPath.row)
        self.collectionView.deleteItems(at: [indexPath])
        
        guard let fetchedResultsController = fetchedResultsController else {
            print("no fetchedResultsController")
            return
        }
        
        for object in fetchedResultsController.fetchedObjects! {
            if object.id == removedCell.id {
                managedObjectContext.delete(object)
                saveContext()
            }
        }
        
        
    }
    

}


extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        // print("configuring cell size")
        let length = view.frame.width / 3 - 15
        return CGSize(width: length, height: length)

    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        
        return UIEdgeInsets(
            top: 15,
            left: 10,
            bottom: 15,
            right: 10
        )

    }
    
    
}
