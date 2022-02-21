//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Dillon on 2/12/22.
//

import Foundation

/// Intermediary used to decouple the `<FeedLoader>` interface from
/// the specific implementation details of the remote/database API.
///
/// Use the static `map(_:_:)` method to transform data received into an
/// array of `[RemoteFeedItem]` and return to `RemoteFeedLoader`
/// to handle the `[FeedItem]` mapping and result completion
internal final class RemoteFeedMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    internal static func mapRemoteItemsFrom(_ data: Data,
                                        with response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard isValid(response), let root = try? mapRootFrom(data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
    
    private static func isValid(_ response: HTTPURLResponse) -> Bool {
        return response.statusCode == 200
    }
    
    private static func mapRootFrom(_ data: Data) throws -> Root {
        return try JSONDecoder().decode(Root.self, from: data)
    }
}

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
