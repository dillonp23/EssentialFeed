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
            do {
                try ManagedCache.replace(with: (feed, timestamp), in: context).saveIfNeeded()
                completion(nil)
            } catch {
                context.rollback()
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.deletePrevious(in: context).saveIfNeeded()
                completion(nil)
            } catch {
                context.rollback()
                completion(error)
            }
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                let cache = try ManagedCache.fetchLatest(in: context)
                completion(Self.mapResultFrom(retrieved: cache))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private static func mapResultFrom(retrieved cache: ManagedCache?) -> FeedStore.RetrievalResult {
        guard let cache = cache else { return .success(.none) }
        
        return .success((feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        moc.perform { [moc] in
            action(moc)
        }
    }
}
