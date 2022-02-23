//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Dillon on 2/20/22.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
