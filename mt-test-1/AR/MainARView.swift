//
//  MainARView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 28.04.22.
//

import UIKit
import SwiftUI
import ARKit
import Combine // Cancellable
import RealityKit
import FocusEntity

extension MainARView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //        // check if found anchors are Plane Anchors
        //        let planeAnchors = anchors.map { $0 as! ARPlaneAnchor }
        //        for planeAnchor in planeAnchors {
        //            let planeEntity = PlaneEntity(with: planeAnchor)
        //            scene.anchors.append(planeEntity)
        //        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //        // Filter to ARPlaneAnchors only
        //        let planeAnchors = anchors.map { $0 as! ARPlaneAnchor }
        //
        //        // Take all IDs of already attached ARPlaneAnchors
        //        let scenePlaneAnchorsID = scene.anchors.map { $0.anchorIdentifier }
        //
        //        // Iterate through each updated ARPlaneAnchor
        //        for planeAnchor in planeAnchors {
        //            // Take id of updated anchor
        //            let id = planeAnchor.identifier
        //
        //            // Look for matching id, if matches, update the transform
        //            if scenePlaneAnchorsID.contains(id) {
        //                print("found!")
        //                let entityToUpdate = (scene.anchors.filter { $0.anchorIdentifier == id }).first
        //                if let a = entityToUpdate as? PlaneEntity {
        //                    print("plane entity")
        //                }
        //                if let b = entityToUpdate as? ARPlaneAnchor {
        //                    print("just plane anchor")
        //                }
        //                if let c = entityToUpdate as? ModelEntity {
        //                    print("model entity")
        //                }
        //            }
        //        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("session interruption ended")
    }
}

class MainARView: ARView {
    static let shared = MainARView()
    
    func setupConfiguration() {
        
        environment.sceneUnderstanding.options = []
        //environment.sceneUnderstanding.options.insert(.physics)
        environment.sceneUnderstanding.options.insert(.occlusion)
        environment.background = Environment.Background.color(.black.withAlphaComponent(0.0))
        
        debugOptions = [
//            .showFeaturePoints,
//            .showAnchorOrigins,
//            .showAnchorGeometry,
//            .showPhysics,
//            .showSceneUnderstanding,
//            .showWorldOrigin
        ]
        
        // For performance, disable render options that are not required for this app.
        renderOptions = [
            //.disableAutomaticLighting, // deprecated
            .disableGroundingShadows,
            .disableMotionBlur,
            //.disableDepthOfField, // we definitely need this
            .disableHDR,
            //.disableFaceOcclusions, // deprecated
            .disablePersonOcclusion,
            .disableAREnvironmentLighting,
            .disableFaceMesh
        ]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .meshWithClassification
        //configuration.environmentTexturing = .automatic

        session.run(configuration)
    }
    
    func setupDummyScene() {
        let coords = [
            SIMD3<Float>(0.0, 0.0, 1.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(-1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, -1.0),
        ]
        for coord in coords {
            let box = MeshResource.generateBox(size: 0.2)
            let material = SimpleMaterial(color: .green, isMetallic: true)
            let entity = ModelEntity(mesh: box, materials: [material])
            let ar = AnchorEntity()
            ar.position = coord
            ar.addChild(entity)
            scene.addAnchor(ar)
        }
    }
    
    func resetSession() {
        let configuration = session.configuration?.copy() as! ARConfiguration
        session.pause()
        /*scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }*/
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
    
        setupDummyScene()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}
