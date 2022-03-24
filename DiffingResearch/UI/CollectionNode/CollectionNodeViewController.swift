//
//  ListViewController.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 16/03/22.
//

import UIKit
import AsyncDisplayKit
import Kingfisher
import DifferenceKit

extension ASCollectionNode {
    
    func reloadDiff<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void
    ) {
        if case .none = view.window, let data = stagedChangeset.last?.data {
            setData(data)
            return reloadData()
        }
        
        for changeset in stagedChangeset {
            if let interrupt = interrupt, interrupt(changeset), let data = stagedChangeset.last?.data {
                setData(data)
                return reloadData()
            }
            
            performBatchUpdates {
                setData(changeset.data)

                if !changeset.sectionDeleted.isEmpty {
                    deleteSections(IndexSet(changeset.sectionDeleted))
                }

                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted))
                }

                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated))
                }

                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }

                if !changeset.elementDeleted.isEmpty {
                    deleteItems(at: changeset.elementDeleted.map { IndexPath(item: $0.element, section: $0.section) })
                }

                if !changeset.elementInserted.isEmpty {
                    insertItems(at: changeset.elementInserted.map { IndexPath(item: $0.element, section: $0.section) })
                }

                if !changeset.elementUpdated.isEmpty {
                    reloadItems(at: changeset.elementUpdated.map { IndexPath(item: $0.element, section: $0.section) })
                }
                
                for (source, target) in changeset.elementMoved {
                    moveItem(at: IndexPath(item: source.element, section: source.section), to: IndexPath(item: target.element, section: target.section))
                }
            }
        }
    }
}

final class MovieCellNode: ASCellNode {
    
    let image = ASNetworkImageNode()
    let title = ASTextNode()
    let desc = ASTextNode()
    
    override init() {
        super.init()
        automaticallyManagesSubnodes = true
    }
    
    func configureMovie(movie: Movie) {
        image.setURL(movie.posterURL, resetToDefault: false)
        title.attributedText = .init(string: movie.title, attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 16, weight: .bold)])
        desc.attributedText = .init(string: movie.overview, attributes: [.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 14, weight: .regular)])
        desc.maximumNumberOfLines = 0
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        image.style.height = .init(unit: .fraction, value: 1)
        image.style.width = .init(unit: .points, value: 120)
        
        let stackText = ASStackLayoutSpec(direction: .vertical, spacing: 6, justifyContent: .start, alignItems: .stretch, children: [
            title, desc
        ])
        
        stackText.style.flexGrow = 2
        stackText.style.flexShrink = 1
        
        let stack = ASStackLayoutSpec(direction: .horizontal, spacing: 10, justifyContent: .start, alignItems: .stretch, children: [
            image, stackText
        ])
        
        return ASInsetLayoutSpec(insets: .init(top: 0, left: 12, bottom: 0, right: 12), child: stack)
    }
}

final class CollectionNodeViewController: ASDKViewController<ASDisplayNode>, ASCollectionDelegate, ASCollectionDataSource {
    
    private lazy var collectionNode: ASCollectionNode = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        flowLayout.scrollDirection = .vertical
        collectionNode.delegate = self
        collectionNode.dataSource = self
        
        return collectionNode
    }()
    
    let reloadButton: ASButtonNode = {
        let btn = ASButtonNode()
        btn.setTitle("Reload", with: UIFont.systemFont(ofSize: 12, weight: .bold), with: UIColor.white, for: .normal)
        btn.backgroundColor = .blue
        return btn
    }()
    
    let performUpdateButton: ASButtonNode = {
        let btn = ASButtonNode()
        btn.setTitle("Perform Update", with: UIFont.systemFont(ofSize: 12, weight: .bold), with: UIColor.white, for: .normal)
        btn.backgroundColor = .blue
        return btn
    }()
    
    let dataFetcher: DataFetcher = DataFetcher.instance
    
    private var movies: [MovieViewModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionNode.reloadData()
            }
        }
    }
    
    init(node: BaseNode) {
        super.init(node: node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func reloadBtnTapped() {
        dataFetcher.reload { movies in
            self.movies = movies
        }
    }
    
    @objc func performUpdateBtnTapped() {
        dataFetcher.performUpdate { movies in
            let diffs = StagedChangeset(source: self.movies, target: movies)
            print(diffs)
            self.collectionNode.reloadDiff(using: diffs, interrupt: nil) { data in
                self.movies = data
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ASCollectionNode"
        self.reloadButton.addTarget(self, action: #selector(self.reloadBtnTapped), forControlEvents: .touchUpInside)
        self.performUpdateButton.addTarget(self, action: #selector(self.performUpdateBtnTapped), forControlEvents: .touchUpInside)
        
        node.backgroundColor = .white
        node.layoutSpecBlock = { node, size in
            self.reloadButton.style.width = .init(unit: .fraction, value: 0.5)
            self.performUpdateButton.style.flexGrow = 1
            let stackButton = ASStackLayoutSpec(direction: .horizontal, spacing: 6, justifyContent: .center, alignItems: .stretch, children: [self.reloadButton, self.performUpdateButton])
            
            stackButton.style.height = .init(unit: .points, value: 50)
            let insetStackbtn = ASInsetLayoutSpec(insets: .init(top: 120, left: 12, bottom: 12, right: 12), child: stackButton)
            self.collectionNode.style.flexGrow = 1
            let stackView = ASStackLayoutSpec(direction: .vertical, spacing: 10, justifyContent: .start, alignItems: .stretch, children: [
                insetStackbtn, self.collectionNode
            ])
            
            return stackView
        }
        
        dataFetcher.fetchMovies()
        dataFetcher.onPopulateMovies = { (movies) in
            self.movies = movies
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        let cell = MovieCellNode()
        cell.configureMovie(movie: movies[indexPath.item].movie)
        return cell
    }
}
