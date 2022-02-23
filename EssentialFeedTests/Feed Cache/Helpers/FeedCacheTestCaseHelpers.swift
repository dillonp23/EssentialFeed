//
//  FeedCacheTestCaseHelpers.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/22/22.
//

import Foundation
import EssentialFeed

func mockUniqueImageFeed() -> [FeedImage] {
    var images = [FeedImage]()
    
    for i in 1...3 {
        images.append(FeedImage(id: UUID(),
                                description: "a description \(i)",
                                location: "a location \(i)",
                                url: URL(string: "http://an-imageURL.com?id=\(i)")!))
    }
    
    return images
}

func mockUniqueFeedWithLocalRep() -> (images: [FeedImage], localRepresentation: [LocalFeedImage]) {
    let images = mockUniqueImageFeed()
    let localImages = images.map {
        LocalFeedImage(id: $0.id,
                       description: $0.description,
                       location: $0.location,
                       url: $0.url)
    }
    
    return (images, localImages)
}

extension Date {
    func adding(days: Int) -> Self {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Self {
        return self.addingTimeInterval(seconds)
    }
}
