//
//  XCTestCaseMemoryLeakTracker.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/14/22.
//

import Foundation
import XCTest

extension XCTestCase {
    func assertNoMemoryLeaks(_ instance: AnyObject,
                             objectName: String,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            let message = "\(objectName) instance should've been deallocated; potential memory leak."
            XCTAssertNil(instance, message, file: file, line: line)
        }
    }
}
