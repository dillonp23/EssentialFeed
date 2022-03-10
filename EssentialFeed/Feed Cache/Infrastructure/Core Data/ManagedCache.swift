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
        let managedFeed = self.feed.compactMap { $0 as? ManagedFeedImage }
        return managedFeed.map { $0.localRepresentation }
    }
    
    static func mapOrderedSet(from localFeed: [LocalFeedImage],
                              in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localFeed.map {
            ManagedFeedImage.mapFrom($0, in: context)
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
    
    /// Deletes previous cache (if present) then creates a new unique `ManagedCache`
    /// instance, performing all operations in the provided `NSManagedObjectContext`.
    @discardableResult
    static func replace(with localCache: (feed: [LocalFeedImage], time: Date),
                        in context: NSManagedObjectContext) throws -> NSManagedObjectContext {
        try ManagedCache.deletePrevious(in: context)
        
        let cache = ManagedCache(context: context)
        cache.timestamp = localCache.time
        cache.feed = ManagedCache.mapOrderedSet(from: localCache.feed, in: context)
        return context
    }
    
    /// Checks if there is a previously saved `ManagedCache` instance and deletes it.
    @discardableResult
    static func deletePrevious(in context: NSManagedObjectContext) throws -> NSManagedObjectContext {
        try ManagedCache.find(in: context).flatMap { context.delete($0) }
        return context
    }
}
