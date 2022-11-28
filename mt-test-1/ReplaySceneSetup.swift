//
//  ReplaySceneSetup.swift
//  mt-test-1
//
//  Created by Kevin Bein on 27.11.22.
//

import Foundation
import RealityKit

class ReplaySceneSetup {
    
    static let sceneSetup = [
        "test": [
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
        ]
    ] as [String : Any]
    
    static func renderSceneNext(forRecording: String, frameNumber: Int, view: MainARView) {
        guard let data = sceneSetup[forRecording] as? [String: [Any]] else { return }
        guard let entry = data[String(frameNumber)] else { return }
        
        let modelName = entry[0] as! String
        var varPosition: SIMD3<Float>
        if ((entry[1] as? String) != nil) {
            if MainARViewContainer.focusEntity != nil {
                varPosition = MainARViewContainer.focusEntity!.position
            } else {
                Log.print("ReplaySceneSetup: No position available (focusEntity)")
                return
            }
        } else {
            varPosition = entry[1] as! SIMD3<Float>
        }
        
        let position = varPosition
        
        var anchor = AnchorEntity(plane: .horizontal)
        anchor.position = position
        guard let model = AccessibleModel.load(named: modelName) else {
            fatalError("ReplaySceneSetup: Failed loading model '\(modelName)'")
        }
        anchor.addChild(model)
        view.scene.addAnchor(anchor)
        
        Log.print("ReplaySceneSetup: (\(frameNumber)) Added model \(modelName) at \(position)")
    }
    
}
