//
//  AppDelegate.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 16/03/22.
//

import UIKit
import AsyncDisplayKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow()
//        window?.rootViewController = ASDKNavigationController(rootViewController: TableNodeViewController(node: BaseNode()))
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
        return true
    }
}


final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.isTranslucent = false
        tabBar.barTintColor = .white
        let tableNode = TableNodeViewController(node: BaseNode())
        tableNode.tabBarItem = .init(title: "TableNode", image: nil, tag: 0)
        
        let collectionNode = CollectionNodeViewController(node: BaseNode())
        collectionNode.tabBarItem = .init(title: "CollectionNode", image: nil, tag: 1)
        
        let collectionView = ViewController()
        collectionView.tabBarItem = .init(title: "CollectionView", image: nil, tag: 2)
        
        viewControllers = [tableNode, collectionNode, collectionView]
    }
}
