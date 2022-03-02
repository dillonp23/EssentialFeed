//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/28/22.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let moc: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", url: storeURL, in: bundle)
        moc = container.newBackgroundContext()
    }
    
    public func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        let context = self.moc
        context.perform {
            do {
                try ManagedCache.create(in: context, using: (feed, timestamp))
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping OperationCompletion) {
        
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let context = self.moc
        context.perform {
            do {
                guard let cache = try ManagedCache.find(in: context) else {
                    return completion(.empty)
                }
                completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
}


// MARK: - Managed Cache & Helpers
@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

private extension ManagedCache {
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: self.entity().name!)
        request.returnsObjectsAsFaults = false
        
        return try context.fetch(request).first
    }
    
    static func create(in context: NSManagedObjectContext,
                       using localCache: (feed: [LocalFeedImage], time: Date)) throws {
        let cache = ManagedCache(context: context)
        cache.timestamp = localCache.time
        cache.feed = ManagedCache.mapOrderedSet(from: localCache.feed, in: context)
        try context.save()
    }
}

private extension ManagedCache {
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


// MARK: - Managed Feed Image & Helpers
@objc(ManagedFeedImage)
private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var imageDescription: String?
    @NSManaged var location: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
}

private extension ManagedFeedImage {
    var localRepresentation: LocalFeedImage {
        return LocalFeedImage(id: self.id,
                              description: self.imageDescription,
                              location: self.location,
                              url: self.url)
    }
}


// MARK: - Core Data Stack Setup & Helpers
private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }
        
        let storeDescriptor = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [storeDescriptor]
        
        var loadingError: Swift.Error?
        container.loadPersistentStores { _, error in
            loadingError = error
        }
        
        try loadingError.map { error in
            throw LoadingError.failedToLoadPersistentStores(error)
        }
        
        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}
