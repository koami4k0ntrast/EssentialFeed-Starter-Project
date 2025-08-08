//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Neutron Stein on 06/08/2025.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            // IMPORTANT to prevent memory leak!
            guard self != nil else { return }
            
            switch result {
            case let .success(data, reponse):
                completion(FeedItemsMapper.map(data, reponse))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
