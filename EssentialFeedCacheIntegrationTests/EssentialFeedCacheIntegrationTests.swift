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
        super.tearDown()
        clearIntegrationTestCacheArtifacts()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
                case let .success(feedImages):
                    XCTAssertEqual(feedImages, [])
                case let .failure(error):
                    XCTFail("Expected successful `load` result, got \(error) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversItemsSavedOnSeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let feedToSave = mockUniqueImageFeed()
        
        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(feedToSave) { saveError in
            XCTAssertNil(saveError, "Expected to save feed successfully")
            saveExp.fulfill()
        }
        
        wait(for: [saveExp], timeout: 1.0)
        
        let loadExp = expectation(description: "Wait for load completion")
        sutToPerformLoad.load { result in
            switch result {
                case let .success(loadedFeed):
                    XCTAssertEqual(loadedFeed, feedToSave)
                case let .failure(error):
                    XCTFail("Expected successful `load` result, got \(error) instead")
            }
            loadExp.fulfill()
        }
        
        wait(for: [loadExp], timeout: 1.0)
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
}
