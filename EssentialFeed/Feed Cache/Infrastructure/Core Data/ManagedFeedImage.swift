//
//  ManagedFeedImage.swift
//  EssentialFeed
//
//  Created by Dillon on 3/2/22.
//

import CoreData

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

extension ManagedFeedImage {
    var localRepresentation: LocalFeedImage {
        return LocalFeedImage(id: self.id,
                              description: self.imageDescription,
                              location: self.location,
                              url: self.url)
    }
    
    static func mapFrom(_ local: LocalFeedImage, in context: NSManagedObjectContext) -> ManagedFeedImage {
        let managedImage = ManagedFeedImage(context: context)
        managedImage.id = local.id
        managedImage.imageDescription = local.description
        managedImage.location = local.location
        managedImage.url = local.url
        return managedImage
    }
}
