//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Dillon on 2/23/22.
//

import Foundation

enum FeedCachePolicy {
    enum Status {
        case expired
        case notExpired
    }
    
    private static let calendar = Calendar(identifier: .gregorian)
    private static let maxCacheAgeInDays = 7
    
    static func validateExpirationStatus(for timestamp: Date, against currentDate: Date) -> Status {
        if let expiration = calendar.date(byAdding: .day, value: -maxCacheAgeInDays, to: currentDate), timestamp <= expiration {
            return .expired
        }
        
        return .notExpired
    }
}
