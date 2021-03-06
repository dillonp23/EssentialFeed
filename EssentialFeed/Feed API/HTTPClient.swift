//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Dillon on 2/13/22.
//

import Foundation

/// The `HTTPClient` protocol enforces functionality to be implemented
/// by any of the EssentialFeed application API modules. The public protocol
/// can be implemented by external modules to initiate a networking request.
///
/// The completion handler can be invoked on any thread; therefore, clients
/// are responsible for dispatching to appropriate threads (if needed).
public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    
    func get(from url: URL, completion: @escaping (Result) -> Void)
}
