//
//  MainARViewContainer.swift
//  mt-test-1
//
//  Created by Kevin Bein on 01.05.22.
//

import UIKit
import ARKit
import SwiftUI
import RealityKit
import FocusEntity

struct MainARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = MainARView()
        
        context.coordinator.view = arView
        arView.session.delegate = context.coordinator
        
        arView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )
        arView.addGestureRecognizer(
            UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan)
            )
        )
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: MainARView?
        var addedModel = false
        var focusEntity: FocusEntity?
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        typealias AR = ARSessionDelegate
        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity, let model = self.view?.model else { return }
            
            if self.addedModel {
                view.scene.removeAnchor(model)
                debugPrint("Removed mansion from ", model.position)
            } else {
                let model2 = try! Mansion.loadScene()
                #if !targetEnvironment(simulator)
                model2.setTransformMatrix(simd_float4x4(1.0), relativeTo: nil)
                model2.position = focusEntity.position
                #endif
                view.scene.addAnchor(model2)
                let mtc = model.transform.matrix.columns
                debugPrint(String(format: "Added mansion at (%.2f,%.2f,%.2f) with rot=%.2f", model.position.x, model.position.y, model.position.z, model.transform.rotation.angle))
                debugPrint(String(format: "[ [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f] ]",
                    mtc.0.x, mtc.0.y, mtc.0.z, mtc.0.w,
                    mtc.1.x, mtc.1.y, mtc.1.z, mtc.1.w,
                    mtc.2.x, mtc.2.y, mtc.2.z, mtc.2.w,
                    mtc.3.x, mtc.3.y, mtc.3.z, mtc.3.w))
            }
            self.addedModel = !self.addedModel
//            // Create a new anchor to add content to
//            let anchor = AnchorEntity()
//            view.scene.addAnchor(anchor)
//            // Add a Box entity with a blue material
//            let box = MeshResource.generateBox(size: 0.5, cornerRadius: 0.05)
//            let material = SimpleMaterial(color: .blue, isMetallic: true)
//            let diceEntity = ModelEntity(mesh: box, materials: [material])
//            #if !targetEnvironment(simulator)
//            diceEntity.position = focusEntity.position
//            #endif
//            anchor.addChild(diceEntity)
        }
        
        var panTranslation: CGPoint?
        @objc func handlePan(sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: self.view)
            if sender.state == .began {
                panTranslation = translation
            } else if sender.state == .changed {
                panTranslation = panTranslation ?? translation
                let xChange = abs(panTranslation!.x - translation.x)
                //let yChange = abs(panTranslation!.y - translation.y)
                //self.view.model.rotate(xChange)
            } else if sender.state != .possible {
                panTranslation = nil
            }
        }
    }
}

//struct MainARViewContainer_Previews: PreviewProvider {
//    static var previews: some View {
//        MainARViewContainer()
//            .edgesIgnoringSafeArea(.all)
//    }
//}
