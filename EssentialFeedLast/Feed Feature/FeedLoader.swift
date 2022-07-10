//
//  FeedLoader.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 15/06/22.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}