//
//  HTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Neutron Stein on 08/08/2025.
//

import EssentialFeed
import XCTest

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_getFromURL_getsDataFromURL() {
        let url = anyURL()

        // Test randomly fails when using method exceptation(description:) instead of direct initialization XCTestExpectation.init(description:)
        // See: https://stackoverflow.com/a/62175055/5603642
        let exp = XCTestExpectation(description: "wait for observation completion")
        URLProtocolStub.observeRequests { capturedRequest in
            // WARNING: as of 2025/08/12 The framework forces trailing "/" when path is empty. So test fails when path is compared with framework-transformed url
            let capturedUrl = capturedRequest.url!
            
            XCTAssertEqual(capturedUrl.absoluteString.removeTrailingSlash(), url.absoluteString.removeTrailingSlash())
            XCTAssertEqual(capturedRequest.httpMethod, "GET")
            
            exp.fulfill()
        }

        makeSUT().get(from: url, completion: { _ in })

        wait(for: [exp], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() {
        let expectedError = anyNSError()

        let error =
            resultErrorFor(data: nil, response: nil, error: expectedError)
            as? NSError

        XCTAssertEqual(error?.domain, expectedError.domain)
        XCTAssertEqual(error?.code, expectedError.code)
    }

    func test_getFromURL_deliversErrorOnAllInvalidRepresentations() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(
            resultErrorFor(
                data: nil,
                response: nonHTTPURLResponse(),
                error: nil
            )
        )
        XCTAssertNotNil(
            resultErrorFor(data: anyData(), response: nil, error: nil)
        )
        XCTAssertNotNil(
            resultErrorFor(data: anyData(), response: nil, error: anyNSError())
        )
        XCTAssertNotNil(
            resultErrorFor(
                data: nil,
                response: nonHTTPURLResponse(),
                error: anyNSError()
            )
        )
        XCTAssertNotNil(
            resultErrorFor(
                data: nil,
                response: anyHTTPURLResponse(),
                error: anyNSError()
            )
        )
        XCTAssertNotNil(
            resultErrorFor(
                data: anyData(),
                response: nonHTTPURLResponse(),
                error: anyNSError()
            )
        )
        XCTAssertNotNil(
            resultErrorFor(
                data: anyData(),
                response: anyHTTPURLResponse(),
                error: anyNSError()
            )
        )
        XCTAssertNotNil(
            resultErrorFor(
                data: anyData(),
                response: nonHTTPURLResponse(),
                error: nil
            )
        )
    }

    func test_getFromURL_succeedsWithDataOnValidData() {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(
            data: data,
            response: response,
            error: nil
        )

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    func test_getFromURL_succeedsWithEmptyDataOnNilData() {
        let emptyData = Data()
        let response = anyHTTPURLResponse()

        let receivedValues = resultValuesFor(
            data: nil,
            response: response,
            error: nil
        )

        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(
            data: data,
            response: response,
            error: error,
            file: file,
            line: line
        )

        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected failure but got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(
            data: data,
            response: response,
            error: error,
            file: file,
            line: line
        )

        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("Expected success but got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClientResult {
        URLProtocolStub.stub(
            data: data,
            response: response,
            error: error
        )
        let sut = makeSUT(file: file, line: line)
        // Test randomly fails when using method exceptation(description:) instead of direct initialization XCTestExpectation.init(description:)
        // See: https://stackoverflow.com/a/62175055/5603642
        let exp = XCTestExpectation(description: "Wait for get completion")

        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }

    private func anyURL() -> URL {
        URL(string: "https://example.com")!
    }

    private func anyData() -> Data {
        Data("any data".utf8)
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 1)
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(
            url: anyURL(),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }
    
    private class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(Self.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(Self.self)
            stub = nil
            requestObserver = nil
        }

        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = .init(data: data, response: response, error: error)
        }
        
        static func observeRequests(_ observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest
        {
            return request
        }

        override func startLoading() {
            if let data = Self.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = Self.stub?.response {
                client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
            }

            if let error = Self.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {

        }
    }
}

extension String {
    func removeTrailingSlash() -> String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
