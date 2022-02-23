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

enum FeedCacheStatus {
    case notExpired
    case atTimeOfExpiration
    case expired
}

extension Date {
    func feedCacheTimestamp(for status: FeedCacheStatus) -> Self {
        let cacheExpiration = self.adding(days: -maxCacheAgeInDays)
        
        switch status {
            case .notExpired:
                return cacheExpiration.adding(seconds: 1)
            case .atTimeOfExpiration:
                return cacheExpiration
            case .expired:
                return cacheExpiration.adding(seconds: -1)
        }
    }
    
    private var maxCacheAgeInDays: Int {
        return 7
    }
    
    private func adding(days: Int) -> Self {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    private func adding(seconds: TimeInterval) -> Self {
        return self.addingTimeInterval(seconds)
    }
}
