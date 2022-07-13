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
            client.complete(withStatusCode: 400, data: makeItemsJSON([]))
        }
    }

    func test_load_deliversError200HTTPResponseWithInvalidData() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(.invalidData)) {
            let invalidData = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidData)
        }
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJsONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        })
     }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()

        let item1 = makeItem(id: UUID(),            imageURL: URL(string: "https://a-image-url.com")!)

        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "https://another-image-url.com")!)

        let items = [item1.model, item2.model]

        expect(sut, toCompleteWith: .success(items), when: {
            client.complete(withStatusCode: 200, data: makeItemsJSON([item1.json, item2.json]))
        })
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://another-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)

        var capturedResults: [RemoteFeedLoader.Result] = []
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))

        XCTAssertTrue(capturedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://another-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)

        return (sut, client)
    }

    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json: [String: Any] = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ].reduce(into: [String: Any]()) { acc, e in
            if let value = e.value { acc[e.key] = value }
        }

        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)

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

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[0].url, statusCode: code, httpVersion: nil, headerFields: nil)!

            messages[index].completion(.success(data, response))
        }
    }
}
