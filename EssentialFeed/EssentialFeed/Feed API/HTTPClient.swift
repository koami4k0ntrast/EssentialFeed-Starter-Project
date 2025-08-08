//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Neutron Stein on 08/08/2025.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
