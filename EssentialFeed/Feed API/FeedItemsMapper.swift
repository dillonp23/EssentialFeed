//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Dillon on 2/12/22.
//

import Foundation

/// Intermediary used to decouple the `<FeedLoader>` interface from
/// the specific implementation details of the backend/database API.
///
/// Use the static `map(_:_:)` method to transform data received from
/// API as `[APIItem]` into the local/usable `[FeedItem]` type.
internal class FeedItemsMapper {
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
    
    /// Transform data received from API as `[APIItem]` into local `[FeedItem]` and
    /// return to `RemoteFeedLoader.Result` completion or return a failure with error
    internal static func mapResultFrom(_ data: Data,
                                       with response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
                  return .failure(RemoteFeedLoader.Error.invalidData)
              }
        
        return .success(root.feedItems)
    }
}
