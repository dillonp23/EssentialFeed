//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Dillon on 3/2/22.
//

import CoreData

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

extension ManagedCache {
    var localFeed: [LocalFeedImage] {
        return managedFeed.map { $0.localRepresentation }
    }
    
    private var managedFeed: [ManagedFeedImage] {
        return self.feed.compactMap { $0 as? ManagedFeedImage }
    }
    
    static func mapOrderedSet(from localFeed: [LocalFeedImage],
                              in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map {
            let managedImage = ManagedFeedImage(context: context)
            managedImage.id = $0.id
            managedImage.imageDescription = $0.description
            managedImage.location = $0.location
            managedImage.url = $0.url
            return managedImage
        })
    }
}

// MARK: Static Core Data Helpers
extension ManagedCache {
    /// Checks if there is a previously saved cache using the `NSFetchRequest` for
    /// the `ManagedCache` entity name, returning the cache if there is one, nil if
    /// the cache is empty, or throwing an error if the request fails.
    ///
    /// Note: an error is thrown only if the `NSFetchRequest` fails, such as if there
    /// is underlying data corruption or an issue with the store.
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: self.entity().name!)
        request.returnsObjectsAsFaults = false
        
        return try context.fetch(request).first
    }
    
    /// Will check whether there is a previously saved cache, and if so, first delete it
    /// before creating and saving a new unique `ManagedCache` instance.
    static func createUniqueInstanceAndSave(in context: NSManagedObjectContext,
                                            using localCache: (feed: [LocalFeedImage], time: Date)) throws {
        try ManagedCache.deleteAndSave(in: context)
        
        let cache = ManagedCache(context: context)
        cache.timestamp = localCache.time
        cache.feed = ManagedCache.mapOrderedSet(from: localCache.feed, in: context)
        try context.save()
    }
    
    static func deleteAndSave(in context: NSManagedObjectContext) throws {
        try ManagedCache.find(in: context).flatMap { context.delete($0) }
        try context.save()
    }
}
