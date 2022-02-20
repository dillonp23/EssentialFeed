//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public protocol FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    
    func insert(_ items: [FeedItem], _ timestamp: Date, completion: @escaping OperationCompletion)
    func deleteCachedFeed(completion: @escaping OperationCompletion)
}
