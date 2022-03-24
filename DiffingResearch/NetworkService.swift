//
//  NetworkService.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 16/03/22.
//

import Foundation

final class URLSessionNetworkService {
    
    private let session: URLSession
    
    public init(configuration: URLSessionConfiguration) {
        self.session = URLSession(configuration: configuration)
    }
    
    public func request(_ url: String, completion: @escaping (Result<[Movie], Error>) -> Void) {
        
        guard var urlComponent = URLComponents(string: url) else {
            let error = NSError(
                domain: "invalid endpoint",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid Endpoint"
                ]
            )
            
            return completion(.failure(error))
        }
        
        var queryItems: [URLQueryItem] = []
        
        let urlQueryItem = URLQueryItem(name: "api_key", value: "ae5b867ee790efe19598ff6108ad4e02")
        urlComponent.queryItems?.append(urlQueryItem)
        queryItems.append(urlQueryItem)
        
        urlComponent.queryItems = queryItems
        
        guard let url = urlComponent.url else {
            let error = NSError(
                domain: "Invalid Endpoint",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid Endpoint"
                ]
            )
            
            return completion(.failure(error))
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                return completion(.failure(error))
            }
            
            guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
                return completion(.failure(
                    NSError(
                        domain: "Invalid Response",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Invalid Response"
                        ]
                )))
            }
            
            guard let data = data else {
                return completion(.failure(
                    NSError(
                        domain: "Data is Nil",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Data is Nil"
                        ]
                    )
                ))
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-mm-dd"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let response = try decoder.decode(MoviesResponse.self, from: data)
                completion(.success(response.results))
            } catch let error as NSError {
                completion(.failure(error))
            }
        }
        .resume()
    }
}
