//
//  FeedItem.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 15/06/22.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
