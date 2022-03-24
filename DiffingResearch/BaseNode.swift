//
//  BaseNode.swift
//  DiffingResearch
//
//  Created by Tifo Audi Alif Putra on 16/03/22.
//

import AsyncDisplayKit

final class BaseNode: ASDisplayNode {
    
    override init() {
        super.init()
        automaticallyManagesSubnodes = true
        automaticallyRelayoutOnSafeAreaChanges = true
        automaticallyRelayoutOnLayoutMarginsChanges = true
    }
}
