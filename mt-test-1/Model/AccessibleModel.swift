//
//  AccessibleModel.swift
//  mt-test-1
//
//  Created by Kevin Bein on 25.04.22.
//

import Foundation // Dates, Strings
import RealityKit

class AccessibleModel: Entity, HasModel, HasAnchoring, HasCollision {
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    required init(entity: Entity) {
        super.init()
        
        name = entity.name 
        
        addAnchoring()
        addModel(entity: entity)
        
        //entity.generateCollisionShapes(recursive: true)
        
        //self.components[ModelComponent.self] = entity.components[ModelComponent.self]
        //self.components[AnchoringComponent.self] = anchor
        //self.position = entity.position
        //print(anchor)
        //self.components = entity.components
    }
    
    private func addModel(entity: Entity) {
        self.addChild(entity)
        
        // Will generate collision boxes automatically also for children
        self.generateCollisionShapes(recursive: true)
    }
    
    private func addAnchoring() {
        #if !targetEnvironment(simulator)
        let anchorPlane = AnchoringComponent.Target.plane(AnchoringComponent.Target.Alignment.horizontal, classification: AnchoringComponent.Target.Classification.floor, minimumBounds: SIMD2<Float>.init(x: 1, y: 1))
        let anchorComponent = AnchoringComponent(anchorPlane)
        self.anchoring = anchorComponent
        #endif
    }
    
    static public func load(named: String) -> AccessibleModel? {
        guard let entity = try? Entity.load(named: named) else {
            print("Error loading model '\(named)'")
            return nil
        }
        let model = AccessibleModel(entity: entity)
        
        if named == "mansion" {
            let scale = SIMD3<Float>.init(repeating: 0.5)
            model.setScale(scale, relativeTo: nil)
        }
        
        return model
    }
    
    /*public init?(fileName: String, fileExtension: String = "usdz") {
        super.init()
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Error finding Reality file \(fileName).\(fileExtension)")
            return nil
        }
        
        //if let anchor = try? Entity.loadAnchor(named: fileName) {
        if let anchor = try? Entity.loadAnchor(contentsOf: url) {
            self.components = anchor.components
        }
    }*/
}
