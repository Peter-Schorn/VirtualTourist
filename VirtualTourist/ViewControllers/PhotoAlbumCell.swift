import Foundation
import UIKit

class PhotoAlbumCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var couldntLoadImageLabel: UILabel!
    
    var id: UUID? = nil
    
    func configure() {
        self.imageView.image = nil
        self.imageView.contentMode = .scaleAspectFill
        self.activityIndicator.hidesWhenStopped = true
        self.couldntLoadImageLabel.isHidden = true
    }
    
}
