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

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Error) -> Void = { _ in }) {
        client.get(from: url) { error, response in
            if let error = error {
                completion(.connectivity)
            } else {
                completion(.invalidData)
            }
        }
    }
}

