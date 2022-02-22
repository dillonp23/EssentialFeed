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
        
        XCTAssertEqual(store.receivedOperations.count, 0)
        XCTAssertEqual(store.retrievalMessages.count, 0)
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.receivedOperations.count, 0)
        XCTAssertEqual(store.retrievalMessages.count, 1)
        XCTAssertEqual(store.retrievalMessages[0].operation, .retrieve)
    }
    
    func test_load_failsOnCacheRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), forAction: {
            store.completeRetrievalWith(retrievalError)
        })
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), forAction: {
            store.completeRetrievalSuccessfully()
        })
    }
    
    func test_load_deliversImagesOnRetrievalSuccessWithNonEmptyCache() {
        let (sut, store) = makeSUT()
        let feed = mockUniqueFeedWithLocalRep()
        
        expect(sut, toCompleteWith: .success(feed.images), forAction: {
            store.completeRetrievalSuccessfully(with: feed.localRepresentation)
        })
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
