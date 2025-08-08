//
//  HTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Neutron Stein on 08/08/2025.
//

import XCTest
import EssentialFeed

class RemoteHTTPClient: HTTPClient {
    let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    func testPerformanceExample() {
        
    }
}

class MockURLProtocol: URLProtocol {
    
}
