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
        let exp = expectation(description: "Wait for load completion")
        
        var capturedError: NSError?
        sut.load { result in
            switch result {
                case .failure(let error as NSError?):
                    capturedError = error
                default:
                    XCTFail("Expected failure, got \(result)")
            }
            exp.fulfill()
        }
        
        store.completeRetrievalWith(retrievalError)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(retrievalError, capturedError)
    }
    
    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()
        let exp = expectation(description: "Wait for load completion")
        
        var capturedImages: [FeedImage]?
        sut.load { result in
            switch result {
                case .success(let images):
                    capturedImages = images
                default:
                    XCTFail("Expected success (w/ no images), got \(result) instead")
            }
            exp.fulfill()
        }
        
        store.completeRetrievalSuccessfully()
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(capturedImages, [])
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
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 1, userInfo: nil)
    }
}
