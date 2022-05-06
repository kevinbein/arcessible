//
//  AccessibleModel.swift
//  mt-test-1
//
//  Created by Kevin Bein on 25.04.22.
//

import Foundation // Dates, Strings
import RealityKit
import SceneKit

//class AccessibleAnchor: AnchorEntity {

class AccessibleModel: Entity, HasModel, HasCollision, HasAnchoring {
    
    required init() {
    }
    
    required init(entity: Entity) {
        super.init()
        name = entity.name
        self.addChild(entity)
        // Will generate collision boxes automatically also for children
        self.generateCollisionShapes(recursive: true)
    }
    
    func rotate(degrees: Float) {
//        let currentMatrix = transform.matrix
//        let rotation = simd_float4x4(SCNMatrix4MakeRotation(.pi / 3.0, 0.0, 1.0, 0.0))
//        let scaling = simd_float4x4(1.0)  //simd_float4x4(SCNMatrix4MakeScale(0.5, 0.5, 0.5))
//        let transform = simd_mul(simd_mul(currentMatrix, rotation), scaling)
//        resetTransform = simd_mul(resetTransform, transform)
//        move(to: transform, relativeTo: self, duration: 1.0, timingFunction: .linear)
//        let rad = (deg * .pi / 180.0) //.truncatingRemainder(dividingBy: 2.0 * .pi)
//        let oldRad = self.transform.rotation.angle
//        let oldDeg = oldRad * 180.0 / .pi
//        let newDeg = oldDeg + deg
        let twoPi = 2 * Float.pi
        var newRad = transform.rotation.angle + (degrees * .pi / 180.0)
        if newRad < 0 {
            newRad = twoPi - newRad
        } else if newRad > twoPi {
            newRad -= twoPi
        }
        let rotation = simd_quatf(angle: newRad, axis: SIMD3<Float>(0.0, 1.0, 0.0))
        transform.rotation = rotation
    }
    
    func scale(factor: Float) {
        scale *= SIMD3<Float>(repeating: factor)
    }
    
    func reset() {
        self.transform = Transform()
    }
    
    static public func load(named: String, scene: String? = "") -> AccessibleModel? {
        guard let realityFileURL = Foundation.Bundle(for: AccessibleModel.self).url(forResource: "mansion", withExtension: "reality") else {
            fatalError("File not found '\(named)'")
        }
        let sceneName = scene ?? named
        let realityFileSceneURL = realityFileURL.appendingPathComponent(sceneName, isDirectory: false)
        let anchorEntity = try! AccessibleModel.loadAnchor(contentsOf: realityFileSceneURL)
        
        let model = AccessibleModel()
        model.anchoring = anchorEntity.anchoring
        model.addChild(anchorEntity)
        return model
        
//        guard let entity = try? Entity.load(named: named) else {
//            return nil
//        }
//
//        let model = AccessibleModel(entity: entity)
//
//        return model
    }
    
    static public func load_old(named: String) -> AccessibleModel? {
        guard let entity = try? Entity.load(named: named) else {
            return nil
        }
        
        let model = AccessibleModel(entity: entity)
        
//        if named == "mansion" {
//            let scale = SIMD3<Float>.init(repeating: 0.5)
//            model.setScale(scale, relativeTo: nil)
//        }
        
        return model
    }
}
