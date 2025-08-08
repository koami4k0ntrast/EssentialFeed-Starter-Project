//
//  HTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Neutron Stein on 08/08/2025.
//

import EssentialFeed
import XCTest

class URLSessionHTTPClient: HTTPClient {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            //            switch (data, response, error) {
            //            case (nil, nil, .some(let error)):
            //                completion(.failure(error))
            //                case (.some(let data), .some(let response as HTTPURLResponse), nil):
            //                completion(.success(data, response))
            //            default:
            //                break
            //            }
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        defer { URLProtocolStub.stopInterceptingRequests() }

        let url = URL(string: "https://example.com")!
        let expectedError = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(
            url,
            data: nil,
            response: nil,
            error: expectedError
        )

        let sut = URLSessionHTTPClient()

        let exp = expectation(description: "Wait for completion")

        sut.get(from: url) { result in
            switch result {
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail(
                    "Unexpected failure with error \(expectedError) but got \(result) instead"
                )
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}

final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private static var stubs = [URL: Stub]()

    static func stub(
        _ url: URL,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        stubs[url] = .init(data: data, response: response, error: error)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        if let url = request.url, stubs[url] != nil {
            return true
        }
        return false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest
    {
        return request
    }

    override func startLoading() {
        let stub = Self.stubs[request.url!]!

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {

    }

    static func startInterceptingRequests() {
        URLProtocol.registerClass(self)
    }

    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(self)
        stubs = [:]
    }
}
