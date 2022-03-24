//
//  TableNodeViewController.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 21/03/22.
//

import UIKit
import AsyncDisplayKit
import Kingfisher
import DifferenceKit

extension ASTableNode {
    
    func reloadDiff<C>(
        using stagedChangeset: StagedChangeset<C>,
        with animation: @autoclosure () -> UITableView.RowAnimation,
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
                    deleteSections(IndexSet(changeset.sectionDeleted), with: animation())
                }

                if !changeset.sectionInserted.isEmpty {
                    insertSections(IndexSet(changeset.sectionInserted), with: animation())
                }
                
                if !changeset.sectionUpdated.isEmpty {
                    reloadSections(IndexSet(changeset.sectionUpdated), with: animation())
                }

                for (source, target) in changeset.sectionMoved {
                    moveSection(source, toSection: target)
                }

                if !changeset.elementDeleted.isEmpty {
                    deleteRows(at: changeset.elementDeleted.map { IndexPath(row: $0.element, section: $0.section) }, with: animation())
                }

                if !changeset.elementInserted.isEmpty {
                    insertRows(at: changeset.elementInserted.map { IndexPath(row: $0.element, section: $0.section) }, with: animation())
                }
                
                if !changeset.elementUpdated.isEmpty {
                    reloadRows(at: changeset.elementUpdated.map { IndexPath(row: $0.element, section: $0.section) }, with: animation())
                }

                for (source, target) in changeset.elementMoved {
                    moveRow(at: IndexPath(row: source.element, section: source.section), to: IndexPath(row: target.element, section: target.section))
                }
            }
        }
    }
}

final class TableNodeViewController: ASDKViewController<ASDisplayNode>, ASTableDelegate, ASTableDataSource {
    
    
    private lazy var tableNode: ASTableNode = {
        let tableNode = ASTableNode()
        tableNode.delegate = self
        tableNode.dataSource = self
        return tableNode
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
    
    private var movies: [MovieViewModel] = []
    
    init(node: BaseNode) {
        super.init(node: node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "ASTableNode"
        self.reloadButton.addTarget(self, action: #selector(self.reloadBtnTapped), forControlEvents: .touchUpInside)
        self.performUpdateButton.addTarget(self, action: #selector(self.performUpdateBtnTapped), forControlEvents: .touchUpInside)
        
        node.backgroundColor = .white
        node.layoutSpecBlock = { node, size in
            self.reloadButton.style.width = .init(unit: .fraction, value: 0.5)
            self.performUpdateButton.style.flexGrow = 1
            let stackButton = ASStackLayoutSpec(direction: .horizontal, spacing: 6, justifyContent: .center, alignItems: .stretch, children: [self.reloadButton, self.performUpdateButton])
            
            stackButton.style.height = .init(unit: .points, value: 50)
            let insetStackbtn = ASInsetLayoutSpec(insets: .init(top: 120, left: 12, bottom: 12, right: 12), child: stackButton)
            self.tableNode.style.flexGrow = 1
            let stackView = ASStackLayoutSpec(direction: .vertical, spacing: 10, justifyContent: .start, alignItems: .stretch, children: [
                insetStackbtn, self.tableNode
            ])
            
            return stackView
        }
        
        dataFetcher.fetchMovies()
        dataFetcher.onPopulateMovies = { (movies) in
            self.movies = movies
            self.tableNode.reloadData()
        }
    }
    
    @objc func performUpdateBtnTapped() {
        dataFetcher.performUpdate { movies in
            let diffs = StagedChangeset(source: self.movies, target: movies)
            self.tableNode.reloadDiff(using: diffs, with: .fade, interrupt: nil) { movies in
                self.movies = movies
            }
        }
    }
    
    @objc func reloadBtnTapped() {
        dataFetcher.reload { movies in
            self.movies = movies
            self.tableNode.reloadData()
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        movies.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        let cell = MovieCellNode()
        cell.configureMovie(movie: movies[indexPath.item].movie)
        return cell
    }
}

