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
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.connectivity)) {
            let error = NSError(domain: "Connectivity", code: 0)
            client.complete(with: error)
        }
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.complete(withStatusCode: 400)
        }
    }

    func test_load_deliversError200HTTPResponseWithInvalidData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidData = Data("invalid json".utf8)
            client.complete(withStatusCode: 400, data: invalidData)
        }
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJson = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJson)
        })
     }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()

        let item1 = FeedItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://a-image-url.com")!)

        let item1JSON = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.description
        ]

        let item2 = FeedItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-image-url.com")!)

        let item2JSON = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.description
        ]

        let itemsJSON = [
            "items": [item1JSON, item2JSON]
        ]

        expect(sut, toCompleteWith: .success([item1, item2]), when: {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://another-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith result: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var capturedResults: [RemoteFeedLoader.Result] = []
        sut.load { capturedResults.append($0) }

        action()

        XCTAssertEqual(capturedResults, [result], file: file, line: line)
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
