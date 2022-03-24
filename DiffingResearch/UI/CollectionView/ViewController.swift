//
//  ViewController.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 16/03/22.
//

import UIKit
import Kingfisher
import DifferenceKit

class MovieCollectionCell: UICollectionViewCell {
    
    static let identifier = String.init(describing: MovieCollectionCell.self)
    
    let movieImage = UIImageView()
    let title = UILabel()
    let desc = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        
        title.font = .systemFont(ofSize: 16, weight: .bold)
        desc.font = .systemFont(ofSize: 14, weight: .regular)
        desc.numberOfLines = 0
        title.setContentHuggingPriority(.init(rawValue: 751), for: .vertical)
        
        let textStack = UIStackView(arrangedSubviews: [title, desc, UIView()])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .top
        textStack.distribution = .fill
        textStack.spacing = 6
        
        movieImage.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(movieImage)
        addSubview(textStack)
        
        NSLayoutConstraint.activate([
            movieImage.topAnchor.constraint(equalTo: topAnchor),
            movieImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            movieImage.bottomAnchor.constraint(equalTo: bottomAnchor),
            movieImage.widthAnchor.constraint(equalToConstant: 140),
            
            textStack.topAnchor.constraint(equalTo: topAnchor),
            textStack.leadingAnchor.constraint(equalTo: movieImage.trailingAnchor),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configureData(data: MovieViewModel) {
        title.text = data.movie.title
        desc.text = data.movie.overview
        movieImage.kf.setImage(with: data.movie.posterURL, placeholder: nil)
    }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        flowLayout.scrollDirection = .vertical
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    let reloadButton = UIButton()
    let performUpdateButton = UIButton()
    
    var movies: [MovieViewModel] = []
    
    let dataFetcher = DataFetcher.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadButton.setTitle("Reload", for: .normal)
        reloadButton.backgroundColor = .blue
        performUpdateButton.setTitle("Perform Update", for: .normal)
        performUpdateButton.backgroundColor = .blue
        
        reloadButton.addTarget(self, action: #selector(self.reload), for: .touchUpInside)
        performUpdateButton.addTarget(self, action: #selector(self.update), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [reloadButton, performUpdateButton])
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.heightAnchor.constraint(equalToConstant: 50),
            
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 150),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.register(MovieCollectionCell.self, forCellWithReuseIdentifier: MovieCollectionCell.identifier)
        
        dataFetcher.fetchMovies()
        dataFetcher.onPopulateMovies = { movies in
            self.movies = movies
            self.collectionView.reloadData()
        }
    }
    
    @objc func reload() {
        dataFetcher.reload { movies in
            self.movies = movies
            self.collectionView.reloadData()
        }
    }
    
    @objc func update() {
        dataFetcher.performUpdate { movies in
            let diff = StagedChangeset(source: self.movies, target: movies)
            self.collectionView.reload(using: diff) { movies in
                self.movies = movies
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionCell.identifier, for: indexPath) as! MovieCollectionCell
        cell.configureData(data: movies[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: view.frame.width, height: view.frame.height / 3)
    }
}

