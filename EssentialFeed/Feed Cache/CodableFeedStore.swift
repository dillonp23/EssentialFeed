//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Dillon on 2/26/22.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeedRepresentation, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], _ timestamp: Date, completion: @escaping OperationCompletion) {
        do {
            let codableFeed = Cache.makeCodable(feed)
            let encodedCache = try JSONEncoder().encode(Cache(feed: codableFeed, timestamp: timestamp))
            try encodedCache.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func deleteCachedFeed(completion: @escaping OperationCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

private struct Cache: Codable {
    let feed: [CodableFeedImage]
    let timestamp: Date
    
    struct CodableFeedImage: Codable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
    }
    
    var localFeedRepresentation: [LocalFeedImage] {
        feed.map {
            LocalFeedImage(id: $0.id,
                           description: $0.description,
                           location: $0.location,
                           url: $0.url)
        }
    }
    
    static func makeCodable(_ localFeed: [LocalFeedImage]) -> [CodableFeedImage] {
        localFeed.map {
            CodableFeedImage(id: $0.id,
                             description: $0.description,
                             location: $0.location,
                             url: $0.url)
        }
    }
}
