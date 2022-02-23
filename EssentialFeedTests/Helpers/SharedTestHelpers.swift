//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Dillon on 2/22/22.
//

import Foundation

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 1, userInfo: nil)
}

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}
