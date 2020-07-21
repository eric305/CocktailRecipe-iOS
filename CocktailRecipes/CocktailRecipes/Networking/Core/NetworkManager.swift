//
//  NetworkManager.swift
//  CocktailRecipes
//
//  Created by Eric Rado on 7/18/20.
//  Copyright © 2020 Eric Rado. All rights reserved.
//

import Foundation

enum NetworkError: String, Error {
	case missingURL = "URL is nil."
	case parameterEncodingFailed = "Parameter encoding failed."
    case unknown
}

final class NetworkManager {
	private let apiKey: String
    private let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
		guard let path = Bundle.main.path(forResource: "APIKey", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) else {
                fatalError("APIKey.plist not found")
        }
        let apiKey = dict["API_KEY"] as? String
        self.apiKey = apiKey ?? "1"
        
        self.session = session
    }

	func request<T: Decodable>(_ endpoint: EndpointConstructable, completion: @escaping (Result<T, Error>) -> Void) {
		do {
			let request = try buildRequest(from: endpoint)
			session.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    completion(.failure(error))
				} else if let data = data {
					do {
						let model = try JSONDecoder().decode(T.self, from: data)
						completion(.success(model))
					} catch let error {
						completion(.failure(error))
					}
                } else {
                    completion(.failure(NetworkError.unknown))
                }
			}.resume()
		} catch let error {
			completion(.failure(error))
		}
	}

	private func buildRequest(from endpoint: EndpointConstructable) throws -> URLRequest {
		guard let url = URL(string: endpoint.baseURL)?.appendingPathComponent("\(apiKey)/\(endpoint.path)") else {
			fatalError("baseURL could not be configured")
		}
		var request = URLRequest(
			url: url,
			cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
			timeoutInterval: 10.0)

		request.httpMethod = endpoint.httpMethod.rawValue

		switch endpoint.httpTask {
		case .request:
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		case.requestParameters(let parameters):
			try encodeParameter(parameters: parameters, with: &request)
		}

		return request
	}

	private func encodeParameter(parameters: Parameters, with request: inout URLRequest) throws {
		let parameterEncoder = URLParameterEncoder()
        try parameterEncoder.encode(urlRequest: &request, with: parameters)
	}
}
