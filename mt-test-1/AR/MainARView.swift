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
    var sub_SceneEventsUpdate: Cancellable!
    var boxAnchor: AnchorEntity?
    var model: AccessibleModel?
    
    func setupConfiguration() {
        session.delegate = self

        environment.sceneUnderstanding.options = []
        
        // Turn on occlusion from the scene reconstruction's mesh.
        //environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Turn on physics for the scene reconstruction's mesh.
        //environment.sceneUnderstanding.options.insert(.physics)

        // Display a debug visualization of the mesh.
        //debugOptions.insert(.showSceneUnderstanding)
#if DEBUG
        self.debugOptions = [
//            .showFeaturePoints,
//            .showAnchorOrigins,
//            .showAnchorGeometry,
//            .showPhysics,
//            .showSceneUnderstanding,
//            .showWorldOrigin
        ]
#endif
        
        // For performance, disable render options that are not required for this app.
        //renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        //automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        //configuration.sceneReconstruction = .meshWithClassification

        //configuration.environmentTexturing = .automatic
        session.run(configuration)
    }
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
        
        model = AccessibleModel.load(named: "mansion")
        model = AccessibleModel.load(named: "boxgreen")
        if model == nil {
            fatalError("Failed to load model mansion.usdz")
        }
        
        // let rcporjectModel = try! Boxgreen.loadScene()
        // arView.scene.anchors.append(rcporjectModel)
        //scene.anchors.append(anchorModel)
//        scene.addAnchor(model!)
        
        //        let box = ModelEntity(
        //          mesh: MeshResource.generateBox(size: 0.05),
        //          materials: [SimpleMaterial(color: .red, isMetallic: true)]
        //        )
        //        let cameraAnchor = AnchorEntity(.camera)
        //        cameraAnchor.addChild(box)
        //        scene.addAnchor(cameraAnchor)
        //        // Move the box in front of the camera slightly, otherwise
        //        // it will be centered on the camera position and we will
        //        // be inside the box and not be able to see it
        //        box.transform.translation = [0, 0, -0.5]
        
        
//        let box2 = ModelEntity(
//            mesh: MeshResource.generateBox(size: 0.1),
//            materials: [SimpleMaterial(color: .red, isMetallic: true)]
//        )
//        box2.transform.translation = [0, 0, -0.5]
//        boxAnchor = AnchorEntity(world: [0,0,0])
//        // scene.addAnchor(boxAnchor!)
//        sub_SceneEventsUpdate = scene.subscribe(to: SceneEvents.Update.self) { event in
//            //            guard let boxAnchor = boxAnchor else {
//            //                return
//            //            }
//            //            // Translation matrix that moves the box 1m in front of the camera
//            //            let translate = float4x4(
//            //                [1,0,0,0],
//            //                [0,1,0,0],
//            //                [0,0,1,0],
//            //                [0,0,-3,1]
//            //            )
//            //            // Transformed applied right to left
//            //            let finalMatrix = self.cameraTransform.matrix * translate
//            //            boxAnchor.setTransformMatrix(finalMatrix, relativeTo: nil)
//            //print(self.cameraTransform.matrix)
//        }
//        boxAnchor!.addChild(box2)
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}
