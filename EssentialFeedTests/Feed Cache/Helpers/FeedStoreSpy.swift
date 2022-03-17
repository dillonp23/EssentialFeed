//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/21/22.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = FeedStore.DeletionCompletion
    typealias InsertionCompletion = FeedStore.InsertionCompletion
    typealias RetrievalCompletion = FeedStore.RetrievalCompletion
    
    enum Message: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve
    }
    
    private(set) var receivedMessages = [Message]()
    private(set) var deletionCompletions = [DeletionCompletion]()
    private(set) var insertionCompletions = [InsertionCompletion]()
    private(set) var retrievalCompletions = [RetrievalCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteCachedFeed)
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(error: Error? = nil, at index: Int = 0) {
        if let error = error {
            deletionCompletions[index](.failure(error))
        } else {
            deletionCompletions[index](.success(()))
        }
    }
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping InsertionCompletion) {
        receivedMessages.append(.insert(feed, timestamp))
        insertionCompletions.append(completion)
    }
    
    func completeInsertion(error: Error? = nil, at index: Int = 0) {
        if let error = error {
            insertionCompletions[index](.failure(error))
        } else {
            insertionCompletions[index](.success(()))
        }
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        receivedMessages.append(.retrieve)
        retrievalCompletions.append(completion)
    }
    
    func completeRetrievalWithFailure(_ error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }
    
    func completeRetrievalSuccessfully(with feed: [LocalFeedImage], timestamp: Date = .now, at index: Int = 0) {
        
        if feed.isEmpty {
            return retrievalCompletions[index](.success(.none))
        }
        
        retrievalCompletions[index](.success((feed: feed, timestamp: timestamp)))
    }
}
