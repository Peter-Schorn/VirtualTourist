import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController:
    UIViewController,
    UIGestureRecognizerDelegate
{
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    var mapPins: [Pin] = []
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate)
            .persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMapRegion()
        
        let gestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(gestureRecognizer:))
        )
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        addPinsToMapFromCoreData()
    }
    
    func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    /// Sets the position and zoom level of the map
    /// using UserDefaults.
    func setMapRegion() { 
        
        guard let regionData = UserDefaults.standard.data(
            forKey: UserDefaultsKey.mapRegion
        ) else {
            print(
                "couldn't get map region data; " +
                "the app may be running for the first time"
            )
            return
        }

        do {
            let region = try JSONDecoder().decode(
                MKCoordinateRegion.self, from: regionData
            )
            self.mapView.setRegion(region, animated: true)
        } catch {
            fatalError("couldn't decode region data:\n\(error)")
        }
        
    }
    
    func addPinsToMapFromCoreData() {
        
        let fetchRequest: NSFetchRequest = Pin.fetchRequest()
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        do {
            try fetchedResultsController.performFetch()
            guard let pins = fetchedResultsController.fetchedObjects else {
                print("no pins found in store")
                return
            }
            
            self.mapPins = pins
            
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = pin.coordinate
                mapView.addAnnotation(annotation)
                // print("added pin")
                
            }
            
        } catch {
            print("couldn't fetch pins from store")
        }
        
        
    }

    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let pressLocation = gestureRecognizer.location(in: mapView)
        let pressCoordinate = mapView.convert(
            pressLocation, toCoordinateFrom: mapView
        )

        // MARK: Create pin
        let annotation = MKPointAnnotation()
        annotation.coordinate = pressCoordinate
        addPinToMap(annotation)
        
    }
    
    // MARK: Add Pin to Map
    func addPinToMap(_ newPin: MKPointAnnotation) {
        
        mapView.addAnnotation(newPin)
        
        let pin = Pin(context: managedObjectContext)
        pin.coordinate = newPin.coordinate
        saveContext()
        
    }
    
}


extension MapViewController: MKMapViewDelegate {
 
    func mapView(
        _ mapView: MKMapView,
        regionDidChangeAnimated animated: Bool
    ) {
        
        do {
            let regionData = try JSONEncoder().encode(mapView.region)
            UserDefaults.standard.set(
                regionData, forKey: UserDefaultsKey.mapRegion
            )
            
        } catch {
            fatalError("couldn't encode region:\n\(error)")
        }
    }
    
    func mapView(_
        mapView: MKMapView,
        didSelect view: MKAnnotationView
    ) {
        
        let coordinate = view.annotation!.coordinate
        let selectedPin = self.mapPins.first { pin in
            pin.coordinate == coordinate
        }
        
        let controller = self.storyboard!.instantiateViewController(
            identifier: "PhotoAlbumViewController"
        ) as! PhotoAlbumViewController
        
        controller.pin = selectedPin
        controller.setupPhotos()
        
        self.show(controller, sender: self)
        
    }
    
    
}
