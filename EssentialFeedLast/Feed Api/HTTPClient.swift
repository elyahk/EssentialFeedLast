//
//  HTTPClient.swift
//  EssentialFeedLast
//
//  Created by Eldorbek on 10/07/22.
//

import Foundation

public enum HTTPClientResult {
    case failure(Error)
    case success(Data, HTTPURLResponse)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
