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
    private let calendar = Calendar(identifier: .gregorian)
    
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
        store.retrieve { [weak self] result in
            
            guard let self = self else { return }
            
            switch result {
                case let .found(feed, timestamp) where self.hasNotExpired(timestamp):
                    completion(.success(feed.modelRepresentation))
                case let .failure(error):
                    completion(.failure(error))
                case .found, .empty:
                    completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .failure:
                    self.store.deleteCachedFeed { _ in }
                case let .found(_, timestamp) where self.isExpired(timestamp):
                    self.store.deleteCachedFeed { _ in }
                case .found, .empty:
                    break
            }
        }
    }
    
    // MARK: Cache Age Validation Helpers
    private func hasNotExpired(_ timestamp: Date) -> Bool {
        guard let expiration = expirationTimestamp else {
            return false
        }
        return timestamp > expiration
    }
    
    private func isExpired(_ timestamp: Date) -> Bool {
        guard let expiration = expirationTimestamp else {
            return false
        }
        return timestamp <= expiration
    }
    
    private var expirationTimestamp: Date? {
        return calendar.date(byAdding: .day, value: -7, to: currentDate())
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
