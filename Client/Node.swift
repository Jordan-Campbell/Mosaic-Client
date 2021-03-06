//
//  Node.swift
//  Client
//
//  Created by Jordan Campbell on 7/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit

class Node {
    
    var key: String = ""
    var nodeValue: String = ""
    var nodeName: String = ""
    var treeDepth: Int = 0
    
    var config: Dictionary<String, Any>?
    var configID: String?

    var text: String = ""
    var href: String = ""
    var imageURL: String = ""
    var requestURL: String = ""
    var modelFilename: String = ""
    var childrenKeys: [String] = []
    var parentKeys: [String] = []
    var attr: [ Dictionary<String, String> ]?
    var style: [ Dictionary<String, Any> ]?
    
    var animations: [Animation] = [Animation]()
    var model: Model = Model()
    
    // AR properties
    var rootNode: SCNNode = SCNNode()
    var geometry: SCNGeometry?
    var x: Float = 0.0
    var y: Float = 0.0
    var totalWidth: Float = 0.0
    var totalHeight: Float = 0.0
    
    var borderSize: [Float] = [0.0, 0.0, 0.0, 0.0]
    var border: [CGRect] = [CGRect(), CGRect(), CGRect(), CGRect()]

    // display properties
    var cell: CGRect = CGRect()
    var image: UIImage?
    var computedStyle: Dictionary<String, Any>?
    let scale: Float = 0.001

    var fonts: [AtlasFont] = [AtlasFont]()
    var font: UIFont = UIFont()
    var defaultFont: UIFont = UIFont()
    var font_size: Float = 0.0
    var font_weight: Float = 0.0

    var color: UIColor = UIColor()
    var backgroundColor: UIColor = UIColor()
    var borderColor: [UIColor] = [UIColor(), UIColor(), UIColor(), UIColor()]

    var inputField: UITextField?        //: Dictionary<String, UITextField> = Dictionary<String, UITextField>()
    
    // false if the node won't be created
    // true if it's fine to render & use this node
    var canRender: Bool = true

    // false if we shouldn't draw any properties to the image (but the node and image should exist)
    // true if we should render this node
    var canDrawOverlay: Bool = true

    var isActive: Bool = false
    
    var isButton: Bool = false
    var canReceiveUserInput: Bool = false
    
    var isAFrameNode: Bool = false
    
    var forceRender: Bool = false
    
    init() {}
    
    init?(_ _data: Dictionary<String, Any>,
          _ _requestURL: String,
          _ _depth: Int,
          _ _config: Dictionary<String, Dictionary<String, Any>>) {
        
        if let _attr = _data["attr"] as? [Dictionary<String, String>] {
            self.attr = _attr
        }
        
        if let id = self.getConfigID() {
            self.configID = id
            if let retrievedConfig = _config[self.configID!] {
                self.config = retrievedConfig
                if let isVisible = self.config!["isVisible"] as? Bool {
                    if isVisible {
                        // if the user set the visibility to true then we override some default checks (like for body etc)
                        self.forceRender = true
                    } else {
                        self.canRender = false
                    }
                }
            } else {
            }
        }
        
        // we will only exit here if the user has specified that this node is
        // not visible
//        if !self.canRender && !self.forceRender {return nil}
        
        self.commonInit(_data, _requestURL, _depth)
        
        self.text = checkText(self.nodeValue)
        let _ = self.setup()
        
        return
        
    }
    
    func commonInit(_ _data: Dictionary<String, Any>,
                    _ _requestURL: String,
                    _ _depth: Int) {
        self.key = _data["key"] as! String
        self.nodeName = _data["nodeName"] as! String
        self.nodeValue = _data["nodeValue"] as! String
        self.rootNode.name = self.key
        self.treeDepth = _depth
        self.requestURL = _requestURL
        self.childrenKeys = _data["nodeChildren"] as! [String]
        self.parentKeys = _data["pkey"] as! [String]
    
        if let _style = _data["nodeStyle"] as? [Dictionary<String, Any>] {
            self.style = _style
        }
        
        self.treeDepth = _data["depth"] as! Int
        
        var tempLayout = _data["nodeLayout"] as! Dictionary<String, Any>
        self.x = tempLayout["x"] as! Float
        self.y = tempLayout["y"] as! Float
        self.totalWidth = tempLayout["width"] as! Float
        self.totalHeight = tempLayout["height"] as! Float
    }
    
    func setup() -> Bool {
        
        self.determineType()

        self.determineProperties()
        
        self.hasStyle()
        
        self.determineLayout()
        
        self.determineFont()
        
        if let _config = self.config {
            self.checkConfig(_config)
        }

        return true
    }
    
}





