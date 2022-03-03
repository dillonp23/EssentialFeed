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
    
    public init(storeType: CoreDataStack.StorageType, bundle: Bundle = .main) throws {
        self.container = try CoreDataStack.createContainer(ofType: storeType, modelName: "FeedStore", in: bundle)
        self.moc = container.newBackgroundContext()
    }
    
    public func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        perform { context in
            do {
                try ManagedCache.createUniqueInstanceAndSave(in: context, using: (feed, timestamp))
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping OperationCompletion) {
        perform { context in
            do {
                try ManagedCache.deleteAndSave(in: context)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
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
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.moc
        context.perform {
            action(context)
        }
    }
}
