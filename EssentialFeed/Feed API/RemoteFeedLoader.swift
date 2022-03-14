//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Dillon on 2/10/22.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url) { [weak self] result in
            
            /// Prevent completion if self has been deallocated
            guard self != nil else { return }
            
            switch result {
                case let .success((data, response)):
                    completion(RemoteFeedLoader.mapResultFrom(data, with: response))
                case .failure:
                    completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
    
    private static func mapResultFrom(_ data: Data, with response: HTTPURLResponse) -> FeedLoader.Result {
        guard let remoteItems = try? RemoteFeedMapper.mapRemoteItemsFrom(data, with: response) else {
            return .failure(Error.invalidData)
        }
        
        return .success(remoteItems.modelRepresentation)
    }
}

private extension Array where Element == RemoteFeedItem {
    var modelRepresentation: [FeedImage] {
        return map {
            FeedImage(id: $0.id,
                     description: $0.description,
                     location: $0.location,
                     url: $0.image)
        }
    }
}
