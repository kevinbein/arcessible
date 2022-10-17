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
        super.init()
        
        // Will generate collision boxes automatically also for children
        self.generateCollisionShapes(recursive: true)
    }
    
    func rotate(degrees: Float) {
        guard let entity = children.first else {
            return
        }
        let twoPi = 2 * Float.pi
        var newRad = entity.transform.rotation.angle + (degrees * .pi / 180.0)
        //var newRad = transform.rotation.angle + (degrees * .pi / 180.0)
        if newRad < 0 {
            newRad = twoPi - newRad
        } else if newRad > twoPi {
            newRad -= twoPi
        }
        let rotation = simd_quatf(angle: newRad, axis: SIMD3<Float>(0.0, 1.0, 0.0))
        entity.transform.rotation = rotation
    }
    
    func scale(factor: Float) {
        guard let entity = children.first else {
            return
        }
        entity.scale *= SIMD3<Float>(repeating: factor)
    }
    
    func reset() {
        self.transform = Transform()
    }
    
    static public func load(named: String, scene: String? = "") -> AccessibleModel? {
        let range = NSRange(location: 0, length: named.count)
        let regex = try! NSRegularExpression(pattern: "([a-zA-Z0-9]+)([.]usdz)")
        var ext = "reality"
        //let result = regex.firstMatch(in: named, options: [], range: range)
        let matches = regex.matches(in: named, options: [], range: range)
        var fileName = named
        if matches.count > 0 {
            let nsString = named as NSString
            let match = matches[0]
            //fileName = nsString.substring(with: match.range) as String
            fileName = nsString.replacingOccurrences(of: ".usdz", with: "")
            ext = "usdz"
        }
        var realityFileURL = Foundation.Bundle(for: AccessibleModel.self).url(forResource: fileName, withExtension: ext)
        if realityFileURL == nil {
            ext = ext == "reality" ? "usdz" : "reality"
            realityFileURL = Foundation.Bundle(for: AccessibleModel.self).url(forResource: fileName, withExtension: ext)
            if realityFileURL == nil {
                fatalError("File not found '\(fileName)'")
            }
        }
        let sceneName = scene ?? fileName
        let realityFileSceneURL = realityFileURL!.appendingPathComponent(sceneName, isDirectory: false)
        let anchorEntity = try! AccessibleModel.loadAnchor(contentsOf: realityFileSceneURL)
        
        let model = AccessibleModel()
        model.anchoring = anchorEntity.anchoring
        model.addChild(anchorEntity)
        return model
    }
}
