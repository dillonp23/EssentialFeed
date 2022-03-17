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
    
    public func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.replace(with: (feed, timestamp), in: context).saveIfNeeded()
            }.mapError {
                context.rollback()
                return $0
            })
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.deletePrevious(in: context).saveIfNeeded()
            }.mapError {
                context.rollback()
                return $0
            })
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            completion(Result {
                try ManagedCache.fetchLatest(in: context).map { cache in
                    return (feed: cache.localFeed, timestamp: cache.timestamp)
                }
            })
        }
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        moc.perform { [moc] in
            action(moc)
        }
    }
}
