//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Peter Schorn on 8/4/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {

    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.creationDate = Date()
        self.id = UUID()
    }
    
}
