//
//  FeedLoader.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 15/06/22.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
