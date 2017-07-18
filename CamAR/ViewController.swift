//
//  ViewController.swift
//  CamAR
//
//  Created by Timothy Hoover on 7/2/17.
//  Copyright © 2017 Timothy Hoover. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Photos
import Foundation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func setScene() {
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.preferredFramesPerSecond = 60
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.maximumExposure = -1
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scene = SCNScene(named: "art.scnassets/Lowpoly_tree_sample.dae")!
        let treeNode = scene.rootNode.childNode(withName: "Tree_lp_11", recursively: true)
        treeNode?.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        if let touch = touches.first {
            let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint] )
            if let anchor = results.first {
                let hitPointTransform = SCNMatrix4(anchor.worldTransform)
                let hitPointPosition = SCNVector3Make(hitPointTransform.m41, hitPointTransform.m42, hitPointTransform.m43)
                treeNode?.position = hitPointPosition
            }
        }
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        sceneView.automaticallyUpdatesLighting = true
        //sceneView.autoenablesDefaultLighting = false
        setScene()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        
        let planeImage = UIImage(named: "art.scnassets/plane_grid.png")
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeImage
        planeMaterial.isDoubleSided = true
        
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        return planeNode
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        let planeNode = createPlaneNode(anchor: planeAnchor)
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let planeNode = createPlaneNode(anchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func render(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        
        node.enumerateChildNodes {
            (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    @IBOutlet weak var screenShot: UIButton!
    @IBAction func takeScreenShot() {
        guard screenShot.isEnabled else {
            return
        }
        
        let takeScreenShotBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async {
                let flashOverlay = UIView(frame: self.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeScreenShotBlock()
        case .restricted, .denied:
            let title = "Photos access denied"
            let message = "Please enable Photos access in Settings > Privacy."
            print(title + message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({(authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenShotBlock()
                }
            })
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
