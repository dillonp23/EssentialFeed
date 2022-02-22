//
//  ValidateCachedFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/22/22.
//

import Foundation
import XCTest
import EssentialFeed

class ValidateCachedFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        sut.validateCache()
        store.completeRetrievalWithFailure(retrievalError)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotRequestDeletionOfEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeleteLessThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let maxValidCacheAge = cacheExpiration.adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.validateCache()
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: maxValidCacheAge)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    
    
    // MARK: - Helpers
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
    
    // MARK: Mocking Data & Errors
    private func mockUniqueImageFeed() -> [FeedImage] {
        var images = [FeedImage]()
        
        for i in 1...3 {
            images.append(FeedImage(id: UUID(),
                                    description: "a description \(i)",
                                    location: "a location \(i)",
                                    url: URL(string: "http://an-imageURL.com?id=\(i)")!))
        }
        
        return images
    }
    
    private func mockUniqueFeedWithLocalRep() -> (images: [FeedImage], localRepresentation: [LocalFeedImage]) {
        let images = mockUniqueImageFeed()
        let localImages = images.map {
            LocalFeedImage(id: $0.id,
                           description: $0.description,
                           location: $0.location,
                           url: $0.url)
        }
        
        return (images, localImages)
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1, userInfo: nil)
    }
}

private extension Date {
    func adding(days: Int) -> Self {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Self {
        return self.addingTimeInterval(seconds)
    }
}
