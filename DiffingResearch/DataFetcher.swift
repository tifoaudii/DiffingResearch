//
//  DataFetcher.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 18/03/22.
//

import Foundation

class DataFetcher {
    
    static let instance = DataFetcher()
    private init() {}
    
    let service = URLSessionNetworkService(configuration: .default)
    
    var displayedMovies: [MovieViewModel] = []
    var movies = [[MovieViewModel]]()
    
    
    var onPopulateMovies: (([MovieViewModel]) -> Void)?
    
    func fetchMovies() {
        
        let dispatchQueue = DispatchQueue(label: "diffing.research.backgroundQueue")
        let dispatchGroup = DispatchGroup()
        let dispatchSemaphore = DispatchSemaphore(value: 4)
        
        dispatchQueue.async(group: dispatchGroup, qos: .userInitiated) {
            dispatchSemaphore.wait()
            
            dispatchGroup.enter()
            self.service.request("https://api.themoviedb.org/3/movie/popular") { result in
                switch result {
                case .success(let data):
                    self.movies.append(data.map { MovieViewModel(movie: $0) })
                case .failure(let error):
                    print(error)
                }
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            self.service.request("https://api.themoviedb.org/3/movie/upcoming") { result in
                switch result {
                case .success(let data):
                    self.movies.append(data.map { MovieViewModel(movie: $0) })
                case .failure(let error):
                    print(error)
                }
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            self.service.request("https://api.themoviedb.org/3/movie/top_rated") { result in
                switch result {
                case .success(let data):
                    self.movies.append(data.map { MovieViewModel(movie: $0) })
                case .failure(let error):
                    print(error)
                }
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            self.service.request("https://api.themoviedb.org/3/movie/now_playing") { result in
                switch result {
                case .success(let data):
                    self.movies.append(data.map { MovieViewModel(movie: $0) })
                case .failure(let error):
                    print(error)
                }
                dispatchGroup.leave()
            }
            
            dispatchSemaphore.signal()
            
        }
        
        dispatchGroup.notify(queue: .main) {
            self.populateDisplayedMovies()
        }
    }
    
    func populateDisplayedMovies() {
        displayedMovies.removeAll()
        let index = (0...3).map { _ in Int.random(in: 0...3) }
        index.forEach {
            self.displayedMovies.append(contentsOf: self.movies[$0])
        }
        print(movies.count)
        onPopulateMovies?(displayedMovies)
    }
    
    func reload(completion: @escaping (([MovieViewModel]) -> Void)) {
        displayedMovies.removeAll()
        let index = (0...3).map { _ in Int.random(in: 0...3) }
        index.forEach {
            self.displayedMovies.append(contentsOf: self.movies[$0])
        }
        
        completion(displayedMovies)
    }
    
    func performUpdate(completion: @escaping (([MovieViewModel]) -> Void)) {
        displayedMovies.removeAll()
        let index = (0...3).map { _ in Int.random(in: 0...3) }
        index.forEach {
            self.displayedMovies.append(contentsOf: self.movies[$0])
        }
        
        completion(displayedMovies)
    }
}
