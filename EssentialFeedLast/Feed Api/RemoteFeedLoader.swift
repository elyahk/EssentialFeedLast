//
//  RemoteFeedLoader.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 10/07/22.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void = { _ in }) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemaMapper.map(data: data, response: response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
