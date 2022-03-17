//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Dillon on 2/15/22.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedRepresentationError: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            completion(Result {
                guard let data = data, let response = response as? HTTPURLResponse else {
                    throw error ?? UnexpectedRepresentationError()
                }
                return (data, response)
            })
        }.resume()
    }
}
