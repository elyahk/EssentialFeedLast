//
//  HTTPClient.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 10/07/22.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}
