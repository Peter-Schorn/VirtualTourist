import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject {

    var coordinate: CLLocationCoordinate2D {
        get {
            return .init(latitude: latitude, longitude: longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
        
    }
    
    
    
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
    }
    
    
}
