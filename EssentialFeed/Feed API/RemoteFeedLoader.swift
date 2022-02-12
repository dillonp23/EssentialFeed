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

public final class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
                case let .success(data, response):
                    do {
                        let feedItems = try FeedItemsMapper.map(data, response)
                        completion(.success(feedItems))
                    } catch {
                        completion(.failure(.invalidData))
                    }
                case .failure:
                    completion(.failure(.connectivity))
            }
        }
    }
}

/// Intermediary used to decouple the `<FeedLoader>` interface from
/// the specific implementation details of the backend/database API.
///
/// Use the static `map(_:_:)` method to transform data received from
/// API as `[APIItem]` into the local/usable `[FeedItem]` type.
private class FeedItemsMapper {
    private struct Root: Decodable {
        private let items: [APIItem]
        
        /// The data received from external API will be decoded into an `APIItem`
        /// and stored in a private array. This effectively prevents issues with mismatch
        /// properties names between API and `FeedLoader`, e.g. the API defines an
        /// `image` property that is mapped to `imageURL` in the local `FeedItem`
        private struct APIItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let image: URL
        }
        
        /// Use this computed property to access the feed returned from the external API.
        /// The private items array `[APIItem]` is mapped into a public `[FeedItem]`
        var feedItems: [FeedItem] {
            items.map {
                FeedItem(id: $0.id,
                         description: $0.description,
                         location: $0.location,
                         imageURL: $0.image)
            }
        }
    }
    
    /// Transform data received from API as `[APIItem]` into the local `[FeedItem]`
    static func map(_ data: Data,
                    _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.feedItems
    }
}
