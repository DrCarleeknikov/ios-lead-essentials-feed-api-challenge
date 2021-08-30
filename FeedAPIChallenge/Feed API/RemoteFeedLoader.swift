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
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }
			switch result {
			case .success((let data, let response)):
				completion(FeedItemsMapper.map(data, from: response))
			case .failure(_):
				completion(.failure(Error.connectivity))
			}
		}
	}
}

internal struct FeedItemsMapper {
	private struct ImageFeedResponse: Decodable {
		let items: [RemoteFeedImage]

		var feedImages: [FeedImage] {
			return items.map(\.feedImage)
		}
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

	internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == 200,
		      let responseRoot = try? JSONDecoder().decode(ImageFeedResponse.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
		return .success(responseRoot.feedImages)
	}
}
