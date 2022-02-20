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
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] deletionError in
            guard let self = self else { return }
            
            guard deletionError == nil else {
                return completion(deletionError)
            }
            
            self.insertToCache(items, completion: completion)
        }
    }
    
    private func insertToCache(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.insert(items.localRepresentation, currentDate()) { [weak self] insertionError in
            guard self != nil else { return }
            completion(insertionError)
        }
    }
}

private extension Array where Element == FeedItem {
    var localRepresentation: [LocalFeedItem] {
        return map {
            LocalFeedItem(id: $0.id,
                          description: $0.description,
                          location: $0.location,
                          imageURL: $0.imageURL)
        }
    }
}
