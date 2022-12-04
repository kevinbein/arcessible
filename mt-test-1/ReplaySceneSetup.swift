//
//  ReplaySceneSetup.swift
//  mt-test-1
//
//  Created by Kevin Bein on 27.11.22.
//

import Foundation
import RealityKit

class ReplaySceneSetup {
    
    struct SceneOptions {
        var hideUi: Bool = false
        var renderOptions: ARView.RenderOptions? = nil
        var debugOptions: ARView.DebugOptions? = nil
    }
    static let sceneOptions: [String : SceneOptions] = [
        "nightInHallway": SceneOptions(hideUi: true, renderOptions: [ // AR Session 27.mov
            .disableGroundingShadows,
            //.disableMotionBlur,
            //.disableDepthOfField, // we definitely need this
            //.disableHDR,
            //.disablePersonOcclusion,
            //.disableAREnvironmentLighting,
            //.disableFaceMesh
        ]),
        "hallwayStatue": SceneOptions(hideUi: true, renderOptions: [ // AR Session 29.mov
            
        ], debugOptions: [
            // .showWorldOrigin
        ]),
    ]
    
    typealias SceneSetup = (modelName: String, position: SIMD3<Float>?, distanceToCamera: Float, distanceToPreviousObject: Float, transform: Transform?)
    static let sceneSetups: [String : [String : SceneSetup]] = [
        "nightInHallway": [
            "350": ( "populating.emptyWall", SIMD3<Float>(-0.7741148, -0.7132727, -4.6045933), 0.59852266, -1.0, nil ),
            "588": ( "populating.chairIconic", SIMD3<Float>(0.9798603, -1.4509728, -5.0851307), 1.1769475, 1.9625357, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 105, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.23)
            ) ),
        ],
        "hallwayStatue": [
            "616": ( "populating.chair", SIMD3<Float>(0.33363578, -1.2779127, -3.9622407), 1.419089, -1.0, Transform(
                scale: SIMD3<Float>(repeating: 1.0),
                rotation: Transform(pitch: 0, yaw: 105, roll: 0).rotation,
                translation: SIMD3<Float>(0.0, 0.0, 0.23)
            )),
        ]
        /*"test": [
            "462": ["piano", SIMD3<Float>(-0.017804492, -1.3335254, -4.184091), "4.1003428"],
            "225": ["mansion", SIMD3<Float>(-0.0039040074, -1.3385773, -1.5196531), "2.0281196"],
        ],
        "test1": [
            "1": ["plant", "focusEntity"]
        ],
        "test2": [
            "779": ["mansion", SIMD3<Float>(0.38980612, -0.23846741, 1.0062145)],
            "594": ["mansion", SIMD3<Float>(-3.4431071, -1.3909823, 2.0340564)],
            "311": ["mansion", SIMD3<Float>(-0.77492774, -1.4330907, -2.9233537)],
        ]*/
    ]
    
    static func setupReplay(forRecording: String) {
        guard let data = sceneSetups[forRecording] else { return }
        guard let options = sceneOptions[forRecording] else { return }
        
        if options.renderOptions != nil {
            MainARView.shared.renderOptions = options.renderOptions!
        }
        
        if (options.debugOptions != nil) {
            MainARView.shared.debugOptions = options.debugOptions!
        }
        
        Log.print("ReplaySceneSetup: Set up replay scene")
    }
    
    static func renderSceneNext(forRecording: String, frameNumber: Int, view: MainARView) {
        guard let data = sceneSetups[forRecording] else { return }
        guard let entry = data[String(frameNumber)] else { return }
        
        let fullName = entry.0
        let nameComponents = fullName.components(separatedBy: ".")
        let modelName = nameComponents[0]
        let sceneName = nameComponents[1]
        
        var varPosition: SIMD3<Float>
        if (entry.position == nil) {
            if MainARViewContainer.focusEntity != nil {
                varPosition = MainARViewContainer.focusEntity!.position
            } else {
                Log.print("ReplaySceneSetup: No position available (focusEntity)")
                return
            }
        } else {
            varPosition = entry.position!
        }
        
        let position = varPosition
        
        var anchor = AnchorEntity(plane: .horizontal)
        anchor.position = position
        guard let model = AccessibleModel.load(named: modelName, scene: sceneName) else {
            fatalError("ReplaySceneSetup: Failed loading model '\(modelName)'")
        }
        
        if entry.transform != nil {
            Log.print("applied transform from", model.children.first!.transform, "to", entry.transform)
            model.children.first!.transform = entry.transform!
        }
        
        anchor.addChild(model)
        view.scene.addAnchor(anchor)
        
        Log.print("ReplaySceneSetup: (\(frameNumber)) Added model \(modelName) at \(position)")
    }
    
}
