//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public final class LocalFeedLoader: FeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public enum ValidationStatus {
        case validated
        case deleted
    }
    
    public typealias ValidationResult = Result<ValidationStatus, Error>
    
    public func validateCache(completion: @escaping (ValidationResult) -> Void = { _ in }) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .failure:
                    self.deleteInvalidCache(completion: completion)
                case let .found(_, timestamp) where self.statusFor(timestamp) == .expired:
                    self.deleteInvalidCache(completion: completion)
                case .empty, .found:
                    completion(.success(.validated))
            }
        }
    }
    
    private func deleteInvalidCache(completion: @escaping (ValidationResult) -> Void) {
        store.deleteCachedFeed { deletionError in
            if let error = deletionError {
                return completion(.failure(error))
            }
            completion(.success(.deleted))
        }
    }
    
    private func statusFor(_ timestamp: Date) -> FeedCachePolicy.Status {
        return FeedCachePolicy.validateExpirationStatus(for: timestamp, against: currentDate())
    }
}

extension LocalFeedLoader {
    public typealias SaveResult = Error?
    
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
}

extension LocalFeedLoader {
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        store.retrieve { [weak self] result in
            
            guard let self = self else { return }
            
            switch result {
                case let .found(feed, timestamp) where self.statusFor(timestamp) == .notExpired:
                    completion(.success(feed.modelRepresentation))
                case let .failure(error):
                    completion(.failure(error))
                case .found, .empty:
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
