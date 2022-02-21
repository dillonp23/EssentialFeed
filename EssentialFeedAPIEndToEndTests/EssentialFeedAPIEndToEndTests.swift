//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Dillon on 2/15/22.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        let testAccountURL = URL(string: "https://www.essentialdeveloper.com/s/feed-case-study-test-api-feed.json")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let feedLoader = RemoteFeedLoader(client: client, url: testAccountURL)
        
        let exp = expectation(description: "Wait for load completion")
        
        var receivedResult: LoadFeedResult?
        feedLoader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 6.0)
        
        assertNoMemoryLeaks(client, objectName: "End-to-End_URLSessionHTTPClient")
        assertNoMemoryLeaks(feedLoader, objectName: "End-to-End_RemoteFeedLoader")
        assertReceivedDataMatchesTestData(receivedResult)
    }
    
    private func assertReceivedDataMatchesTestData(_ result: LoadFeedResult?, file: StaticString = #filePath, line: UInt = #line) {
        let failureMessage = "Expected success result with `[FeedImage]`, but got"
        switch result {
            case .success(let imageFeed):
                assertMockFeedMatchesReceived(imageFeed)
            case .failure(let error):
                XCTFail("\(failureMessage) \(error) instead.")
            default:
                XCTFail("\(failureMessage) nil instead.")
        }
    }
    
    private func assertMockFeedMatchesReceived(_ imageFeed: [FeedImage]) {
        XCTAssertEqual(imageFeed.count, 8, "Expected 8 feed images returned from test server")
        assertMockImageMatchesReceived(imageFeed[0], atIndex: 0)
        assertMockImageMatchesReceived(imageFeed[1], atIndex: 1)
        assertMockImageMatchesReceived(imageFeed[2], atIndex: 2)
        assertMockImageMatchesReceived(imageFeed[3], atIndex: 3)
        assertMockImageMatchesReceived(imageFeed[4], atIndex: 4)
        assertMockImageMatchesReceived(imageFeed[5], atIndex: 5)
        assertMockImageMatchesReceived(imageFeed[6], atIndex: 6)
        assertMockImageMatchesReceived(imageFeed[7], atIndex: 7)
    }
    
    private func assertMockImageMatchesReceived(_ image: FeedImage, atIndex index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let mockImage = rawMockData[index]
        
        guard let uuid = UUID(uuidString: mockImage["id"]!), let url = URL(string: mockImage["image"]!) else {
            XCTFail("Unable to load mock FeedImage from raw data at index \(index)", file: file, line: line)
            return
        }
        
        let expectedImage = FeedImage(id: uuid, description: mockImage["description"], location: mockImage["location"], url: url)
        XCTAssertEqual(expectedImage, image, file: file, line: line)
    }
    
    
    private let rawMockData = [
        ["id": "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6", "description": "Description 1", "location": "Location 1", "image": "https://url-1.com"],
        ["id": "BA298A85-6275-48D3-8315-9C8F7C1CD109", "location": "Location 2", "image": "https://url-2.com"],
        ["id": "5A0D45B3-8E26-4385-8C5D-213E160A5E3C", "description": "Description 3", "image": "https://url-3.com"],
        ["id": "FF0ECFE2-2879-403F-8DBE-A83B4010B340", "image": "https://url-4.com"],
        ["id": "DC97EF5E-2CC9-4905-A8AD-3C351C311001", "description": "Description 5", "location": "Location 5", "image": "https://url-5.com"],
        ["id": "557D87F1-25D3-4D77-82E9-364B2ED9CB30", "description": "Description 6", "location": "Location 6", "image": "https://url-6.com"],
        ["id": "A83284EF-C2DF-415D-AB73-2A9B8B04950B", "description": "Description 7", "location": "Location 7", "image": "https://url-7.com"],
        ["id": "F79BD7F8-063F-46E2-8147-A67635C3BB01", "description": "Description 8", "location": "Location 8", "image": "https://url-8.com"]
    ]
}
