//
//  FeedStore+CoreDataStackTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 3/3/22.
//

import XCTest
import EssentialFeed
import CoreData

class CoreDataStackTests: XCTestCase {
    func test_createContainer_throwsErrorOnProhibitedStoreURL() {
        let bundle = Bundle(for: CoreDataFeedStore.self)
        let badURL = FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
        
        XCTAssertThrowsError(try CoreDataStack.createContainer(ofType: .persistent(url: badURL),
                                                               modelName: "FeedStore", in: bundle))
    }
}
