//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public protocol FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (Result<[LocalFeedImage], Error>) -> Void
    
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion)
    func deleteCachedFeed(completion: @escaping OperationCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
