//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Dillon on 2/10/22.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

/// The `HTTPClient` protocol enforces functionality to be implemented
/// by any of the EssentialFeed application API modules. The public protocol
/// can be implemented by external modules to initiate a networking request.
public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            
            /// Prevent completion if self has been deallocated
            guard self != nil else { return }
            
            switch result {
                case let .success(data, response):
                    completion(FeedItemsMapper.mapResultFrom(data, with: response))
                case .failure:
                    completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }
}
