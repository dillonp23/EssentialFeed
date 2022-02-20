//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/19/22.
//

import Foundation

public protocol FeedStore {
    typealias OperationCompletion = (Error?) -> Void
    
    func insert(_ items: [LocalFeedItem], _ timestamp: Date, completion: @escaping OperationCompletion)
    func deleteCachedFeed(completion: @escaping OperationCompletion)
}

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL
    
    public init(id: UUID,
                description: String?,
                location: String?,
                imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
