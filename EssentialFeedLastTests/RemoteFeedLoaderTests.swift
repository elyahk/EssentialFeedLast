//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedLastTests
//
//  Created by Eldorbek on 10/07/22.
//

import Foundation
import XCTest
import EssentialFeedLast

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestsDataFromURL() {
        let client = makeSUT().client

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURLs, [url])

    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)

        var capturedErrors: [RemoteFeedLoader.Error] = []
        sut.load { capturedErrors.append($0) }

        let error = NSError(domain: "Connectivity", code: 0)
        client.complete(with: error)

        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "https://another-url.com")!
        let (sut, client) = makeSUT(url: url)

        var capturedErrors: [RemoteFeedLoader.Error] = []
        sut.load { capturedErrors.append($0) }

        client.complete(withStatusCode: 400)

        XCTAssertEqual(capturedErrors, [.invalidData])
    }

    func test_load_deliversError200HTTPResponseWithInvalidData() {
        let (sut, client) = makeSUT()

        var capturedErrors: [RemoteFeedLoader.Error] = []
        sut.load { capturedErrors.append($0) }

        let invalidData = Data("invalid json".utf8)
        client.complete(withStatusCode: 400, data: invalidData)

        XCTAssertEqual(capturedErrors, [.invalidData])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://another-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var messages: [(url: URL, completion: (HTTPClientResult) -> Void)] = []

        var requestedURLs: [URL] {
            messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[0].url, statusCode: code, httpVersion: nil, headerFields: nil)!

            messages[index].completion(.success(data, response))
        }
    }
}
