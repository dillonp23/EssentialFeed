//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/21/22.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
    }
    
    private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
    
    func deleteCachedFeed(completion: @escaping OperationCompletion) {
        receivedOperations.append((.deleteCachedFeed, completion))
    }
    
    func completeDeletion(error: Error? = nil, at index: Int = 0) {
        guard receivedOperations[index].operation == .deleteCachedFeed else { return }
        receivedOperations[index].completion(error)
    }
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        receivedOperations.append((.insert(feed, timestamp), completion))
    }
    
    func completeInsertion(error: Error? = nil, at index: Int = 1) {
        guard receivedOperations[index].operation != .deleteCachedFeed else { return }
        receivedOperations[index].completion(error)
    }
}
