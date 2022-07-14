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

    init(session: URLSession) {
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
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)

        sut.get(from: url) { _ in }

        XCTAssertEqual(task.callCount, 1)
    }

    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://a-url.com")!
        let session = URLSessionSpy()
        let expectedError = NSError(domain: "any error", code: 0)
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task, error: expectedError)
        let sut = URLSessionHTTPClient(session: session)

        let exp = expectation(description: "Wait for get data from url")
        sut.get(from: url) { result in
            switch result {
            case .failure(let recievedError):
                XCTAssertEqual(recievedError as NSError, expectedError)
            default:
                XCTFail("Expected error: \(expectedError), but got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private class URLSessionSpy: URLSession {
        var stubs: [URL: Stub] = [:]

        struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }

        func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: NSError? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }

        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else { return FakeURLSessionDataTask() }

            completionHandler(nil, nil, stub.error)

            return stub.task
        }
    }

    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {
        }
    }
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var callCount = 0

        override func resume() {
            callCount += 1
        }
    }
}

