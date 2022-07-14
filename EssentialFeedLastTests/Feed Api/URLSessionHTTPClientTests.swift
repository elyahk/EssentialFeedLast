//
//  URLSessionHTTPClient.swift
//  EssentialFeedLastTests
//
//  Created by Eldorbek on 14/07/22.
//

import XCTest
import EssentialFeedLast

class URLSessionHTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_failsOnRequestError() {
        URLSessionProtocolStub.startIntercepting()
        let url = URL(string: "https://a-url.com")!
        let expectedError = NSError(domain: "any error", code: 1, userInfo: nil)
        URLSessionProtocolStub.stub(url: url, data: nil, response: nil, error: expectedError)
        let sut = URLSessionHTTPClient()

        let exp = expectation(description: "Wait for get data from url")
        sut.get(from: url) { result in
            switch result {
            case .failure(let recievedError as NSError):
                XCTAssertEqual(recievedError.code, expectedError.code)
                XCTAssertEqual(recievedError.domain, expectedError.domain)
            default:
                XCTFail("Expected error: \(expectedError), but got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        URLSessionProtocolStub.stopIntercepting()
    }

    private class URLSessionProtocolStub: URLProtocol {
        static var stubs: [URL: Stub] = [:]

        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func startIntercepting() {
            URLProtocol.registerClass(URLSessionProtocolStub.self)
        }

        static func stopIntercepting() {
            URLProtocol.unregisterClass(URLSessionProtocolStub.self)
            stubs = [:]
        }

        static func stub(url: URL, data: Data? = nil, response: URLResponse? = nil, error: NSError? = nil) {
            stubs[url] = Stub(data: data, response: response, error: error)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }

            return stubs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url, let stub = URLSessionProtocolStub.stubs[url] else {
                return
            }

            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {
        }
    }
}

