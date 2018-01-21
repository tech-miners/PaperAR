//
//  LinkedList.swift
//  ARKitInteraction
//
//  Created by Jay on 21/01/2018.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import SceneKit

class LinkedList {
    fileprivate var head : Node?
    private var tail : Node?
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public var first: Node? {
        return head
    }
    
    public var last: Node? {
        return tail
    }
    
    public func append(value: CGPoint) {
        let newNode = Node(value : value)
        
        if let tailNode = tail {
            newNode.previous = tailNode
            tailNode.next = newNode
        } else {
            head = newNode
        }
        tail = newNode
    }
    
    public var dequeue: Node? {
        let ret = head
        head = head?.next
        head?.previous = nil
        
        return ret
    }
}

class Node {
    var value : CGPoint
    var next : Node?
    weak var previous : Node?
    
    init(value : CGPoint) {
        self.value = value
    }
}
