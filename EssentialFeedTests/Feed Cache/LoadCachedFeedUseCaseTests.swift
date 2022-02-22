//
//  LoadCachedFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/21/22.
//

import Foundation
import XCTest
import EssentialFeed

class LoadCachedFeedUseCaseTests: XCTestCase {
    
    func test_init_doesNotDeliverLoadMessageUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), forAction: {
            store.completeRetrievalWithFailure(retrievalError)
        })
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: [])
        })
    }
    
    func test_load_deliversImagesOnRetrievalSuccessForLessThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let maxValidCacheAge = cacheExpiration.adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success(feed.images), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: maxValidCacheAge)
        })
    }
    
    func test_load_deliversEmptyFeedOnRetrievalSuccessForExactlySevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: cacheExpiration)
        })
    }
    
    func test_load_deliversEmptyFeedOnRetrievalSuccessForMoreThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let moreThanSevenDays = cacheExpiration.adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: moreThanSevenDays)
        })
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        sut.load { _ in }
        store.completeRetrievalWithFailure(retrievalError)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotRequestDeletionOnSuccessfulRetrievalWithEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotRequestDeletionOfLessThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let maxValidCacheAge = cacheExpiration.adding(seconds: 1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: maxValidCacheAge)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_requestsDeletionOfExactlySevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: cacheExpiration)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_requestsDeletionOfMoreThanSevenDayOldCache() {
        let fixedCurrentDate = Date()
        let cacheExpiration = fixedCurrentDate.adding(days: -7)
        let moreThanSevenDays = cacheExpiration.adding(seconds: -1)
        
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let feed = mockUniqueFeedWithLocalRep()
        
        sut.load { _ in }
        store.completeRetrievalSuccessfully(with: feed.localRepresentation, timestamp: moreThanSevenDays)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var capturedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        store.completeRetrievalSuccessfully(with: [])
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
}

extension LoadCachedFeedUseCaseTests {
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        assertNoMemoryLeaks(store, objectName: "FeedStore_Cache", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "LocalFeedLoader_Cache", file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader,
                        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
                        forAction action: () -> Void,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        
        let exp = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (expectedResult, receivedResult) {
                case let (.success(expectedImages), .success(receivedImages)):
                    XCTAssertEqual(expectedImages, receivedImages, file: file, line: line)
                case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
                    XCTAssertEqual(expectedError, receivedError, file: file, line: line)
                default:
                    let (expRes, recRes) = (expectedResult, receivedResult)
                    XCTFail("Expected \(expRes), got \(recRes) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
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
