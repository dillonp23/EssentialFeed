//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public typealias CachedFeed = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    
    typealias RetrievalResult = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void
    
    /// The completion handler can be invoked on any thread; therefore, clients
    /// are responsible for dispatching to appropriate threads (if needed).
    func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion)
    
    /// The completion handler can be invoked on any thread; therefore, clients
    /// are responsible for dispatching to appropriate threads (if needed).
    func deleteCachedFeed(completion: @escaping OperationCompletion)
    
    /// The completion handler can be invoked on any thread; therefore, clients
    /// are responsible for dispatching to appropriate threads (if needed).
    func retrieve(completion: @escaping RetrievalCompletion)
}
