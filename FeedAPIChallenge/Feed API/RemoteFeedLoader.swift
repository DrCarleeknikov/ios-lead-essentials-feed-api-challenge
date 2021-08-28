//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
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

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { result in
			switch result {
			case .success((let data, let response)):
				switch response.statusCode {
				case 200:
					if let result = try? JSONDecoder().decode(ImageFeedResponse.self, from: data) {
						completion(.success(result.images))

					} else {
						completion(.failure(Error.invalidData))
					}
				default:
					completion(.failure(Error.invalidData))
				}
			case .failure(_):
				completion(.failure(Error.connectivity))
			}
		}
	}
}

private struct ImageFeedResponse: Decodable {
	let items: [RemoteFeedImage]
	var images: [FeedImage] { items.map(\.feedImage) }
}

private struct RemoteFeedImage: Decodable {
	let id: UUID
	let description: String?
	let location: String?
	let url: URL

	var feedImage: FeedImage {
		FeedImage(id: id, description: description, location: location, url: url)
	}

	private enum CodingKeys: String, CodingKey {
		case id = "image_id"
		case description = "image_desc"
		case location = "image_loc"
		case url = "image_url"
	}
}
