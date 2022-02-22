//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self = self else { return }
            
            guard deletionError == nil else {
                return completion(deletionError)
            }
            
            self.insertToCache(feed, completion: completion)
        }
    }
    
    private func insertToCache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.localRepresentation, currentDate()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            
            switch result {
                case let .found(feed, timestamp):
                    let cal = Calendar(identifier: .gregorian)
                    let expirationTimestamp = cal.date(byAdding: .day, value: -7, to: self.currentDate())!
                    
                    if timestamp > expirationTimestamp {
                        completion(.success(feed.modelRepresentation))
                    } else {
                        completion(.success([]))
                    }
                case let .failure(error):
                    completion(.failure(error))
                case .empty:
                    completion(.success([]))
            }
        }
    }
}

private extension Array where Element == FeedImage {
    var localRepresentation: [LocalFeedImage] {
        return map {
            LocalFeedImage(id: $0.id,
                           description: $0.description,
                           location: $0.location,
                           url: $0.url)
        }
    }
}

private extension Array where Element == LocalFeedImage {
    var modelRepresentation: [FeedImage] {
        return map {
            FeedImage(id: $0.id,
                      description: $0.description,
                      location: $0.location,
                      url: $0.url)
        }
    }
}
