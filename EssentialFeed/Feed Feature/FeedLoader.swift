//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Dillon on 2/10/22.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
