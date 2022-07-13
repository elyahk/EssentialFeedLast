//
//  FeedItemaMapper.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 13/07/22.
//

import Foundation

internal class FeedItemaMapper {
    static func map(data: Data, response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return try JSONDecoder().decode(Root.self, from: data).items.map { $0.feedItem }
    }

    static var OK_200: Int { return 200 }

    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var feedItem: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
}
