//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Dillon on 3/5/22.
//

import XCTest
import EssentialFeed

class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        clearIntegrationTestCacheArtifacts()
    }
    
    override func tearDown() {
        clearIntegrationTestCacheArtifacts()
        super.tearDown()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toLoad: [])
    }
    
    func test_load_deliversItemsSavedOnSeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feed = mockUniqueImageFeed()
        
        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(feed) { saveError in
            XCTAssertNil(saveError, "Expected to save feed successfully")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
        
        expect(sutToPerformLoad, toLoad: feed)
    }
    
    func test_save_overridesItemsSavedOnSeparateInstance() {
        let sutToPerformSave = makeSUT()
        let oldFeed = mockUniqueImageFeed()
        save(oldFeed, to: sutToPerformSave)
        
        let sutToOverrideSave = makeSUT()
        let newFeed = mockUniqueImageFeed()
        save(newFeed, to: sutToOverrideSave)
        
        let sutToPerformLoad = makeSUT()
        expect(sutToPerformLoad, toLoad: newFeed)
    }
}


// MARK: Helpers
extension EssentialFeedCacheIntegrationTests {
    private func clearIntegrationTestCacheArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let store = try! CoreDataFeedStore(storeType: .persistent(url: testSpecificStoreURL), bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        assertNoMemoryLeaks(store, objectName: "Cache_CI_PersistentCoreDataFeedStore", file: file, line: line)
        assertNoMemoryLeaks(sut, objectName: "Cache_CI_LocalFeedLoader", file: file, line: line)
        return sut
    }
    
    private var testSpecificStoreURL: URL {
        return cachesDirectory.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func expect(_ sut: LocalFeedLoader, toLoad expectedFeed: [FeedImage],
                        file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
                case let .success(receivedFeed):
                    XCTAssertEqual(expectedFeed, receivedFeed, file: file, line: line)
                case let .failure(error):
                    XCTFail("Expected to load \(expectedFeed), got \(error) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func save(_ feed: [FeedImage], to sut: LocalFeedLoader,
                      file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        sut.save(feed) { error in
            XCTAssertNil(error, "Expected to save feed successfully", file: file, line: line)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
