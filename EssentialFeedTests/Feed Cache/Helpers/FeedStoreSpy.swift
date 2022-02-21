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
    typealias RetrievalCompletion = (Result<[LocalFeedImage]?, Error>) -> Void
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedOperations = [(operation: Message, completion: OperationCompletion)]()
    
    private(set) var retrievalMessages = [(operation: Message, completion: RetrievalCompletion)]()
    
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
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        retrievalMessages.append((.retrieve, completion))
    }
    
    func completeRetrievalWith(_ error: Error, at index: Int = 0) {
        guard retrievalMessages[index].operation == .retrieve else { return }
        retrievalMessages[index].completion(.failure(error))
    }
    
    func completeRetrievalSuccessfully(at index: Int = 0) {
        guard retrievalMessages[index].operation == .retrieve else { return }
        retrievalMessages[index].completion(.success(nil))
    }
}
