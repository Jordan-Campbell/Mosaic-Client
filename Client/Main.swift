//
//  ViewController.swift
//  Client
//
//  Created by Jordan Campbell on 25/01/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftyJSON

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let client = Client()
    let trackingStatus = false
    let button = UIButton()
    
    let animate_tests = AnimateTest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let recogniser = UIPanGestureRecognizer(target: self, action: #selector(handleGestures))
        self.sceneView.addGestureRecognizer(recogniser)
        
        DEBUG = false
        if DEBUG {
            client.request(withURL: "http://1c61d4a0.ngrok.io")//, true)
        } else {
//            client.request(withURL: "http://atlasreality.xyz", false)
//            client.request(withURL: "http://1c61d4a0.ngrok.io")//, true)
            addButton()
        }
    }

    func setup() {
        // don't run the AR session in debug mode
        if !DEBUG {
            self.sceneView.scene.rootNode.addChildNode(client.rootNode)
            self.sceneView.addSubview(client.field)
        }
    }
    
    @objc public func buttonPress() {
        self.client.currentDomain.explosion()
//        client.request(withURL: "atlasreality.xyz", true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touchLocation = touches.first?.location(in: self.sceneView) {
            if let hit = self.sceneView.hitTest(touchLocation, options: nil).first {
                guard let nodeName = hit.node.name else {
                    return
                }
                if nodeName == "searchBarNode" {
                    client.field.becomeFirstResponder()
                } else if nodeName == "searchBarButtonNode" {
                    guard let search = client.field.text else { return }
                    client.field.resignFirstResponder()
                    client.request(withURL: search)
                } else {
                    
                    // will fail if we haven't got a domain yet
                    guard let currentDomain = client.currentDomain else {return}
                    
                    guard let tappedNode = currentDomain.getNode(withKey: nodeName) else {return}
                    if tappedNode.isButton {
                        client.request(withURL: tappedNode.href)
                    }
                }
            }
        }
    }
    
    @objc func handleGestures(_ gesture: UIPanGestureRecognizer) {
        let touch = gesture.location(in: self.sceneView)
        let velocity = gesture.velocity(in: self.sceneView)
        self.client.currentDomain?.scroll( velocity )
        if let _ = self.sceneView.hitTest(touch, types: ARHitTestResult.ResultType.featurePoint).first {}
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if self.trackingStatus == false {
            if let state = self.sceneView.session.currentFrame?.camera.trackingState {
                switch(state) {
                case .normal:
                    self.setup()
                case .notAvailable:
                    break
                case .limited(let _):
                    break
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        self.sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.automaticallyUpdatesLighting = true
        
        if !DEBUG {
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        // 3
        plane.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(CGFloat(0.4))
        
        // 4
        let planeNode = SCNNode(geometry: plane)
        
        // 5
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        // 6
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
    
}


extension ViewController {
    func addButton() {
        let bx = CGFloat((self.sceneView.bounds.maxX/2) - 24)
        let by = CGFloat(self.sceneView.bounds.maxY - 80)
        button.frame = CGRect(x: bx, y: by, width: CGFloat(48), height: CGFloat(48))
        button.backgroundColor = .clear
        let buttonIcon = UIImage(named: "add")
        button.setImage(buttonIcon, for: .normal)
        button.backgroundColor = UIColor(displayP3Red: 255, green: 255, blue: 255, alpha: 0.5)
        button.addTarget(self, action: #selector(buttonPress), for: .touchUpInside)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        button.clipsToBounds = true
        self.sceneView.addSubview(button)
    }
}





