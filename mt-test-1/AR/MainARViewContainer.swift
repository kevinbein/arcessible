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
        // model = try! Mansion.loadScene()
        
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
        
        var loadedModel: Mansion._Mansion
        var model: Mansion._Mansion
        var addedModel = false
        var focusEntity: FocusEntity?
        
        override init() {
            loadedModel = try! Mansion.load_Mansion()
            self.model = loadedModel
            
            super.init()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleButton1Pressed(_:)), name: Notification.Name("Button1Pressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleButton2Pressed(_:)), name: Notification.Name("Button2Pressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleButton3Pressed(_:)), name: Notification.Name("Button3Pressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSlider1Changed(_:)), name: Notification.Name("Slider1Changed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSlider2Changed(_:)), name: Notification.Name("Slider2Changed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSlider3Changed(_:)), name: Notification.Name("Slider3Changed"), object: nil)
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        @objc func handleButton1Pressed(_ notification: Notification) {
            let currentMatrix = self.model.transform.matrix
            let rotation = simd_float4x4(SCNMatrix4MakeRotation(.pi / 2, 0,1,0))
            let transform = simd_mul(currentMatrix, rotation)
            self.model.move(to: transform, relativeTo: nil, duration: 3.0, timingFunction: .linear)
            debugPrint("handleButton1Pressed")
        }
        
        @objc func handleButton2Pressed(_ notification: Notification) {
            let newPos = self.model.position - SIMD3(0.0, 0.0, 0.5)
            self.model.setScale(self.model.scale - SIMD3(repeating: 0.2), relativeTo: nil)
            self.model.setPosition(newPos, relativeTo: nil)
            debugPrint(String(format: "handleButton2Pressed: New position: (%.2f, %.2f, %.2f)", self.model.position.x, self.model.position.y, self.model.position.z))
        }
        
        @objc func handleButton3Pressed(_ notification: Notification) {
            debugPrint("handleButton3Pressed")
        }
        
        @objc func handleSlider1Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            debugPrint("handleSlider1Changed", value)
        }
        
        @objc func handleSlider2Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            debugPrint("handleSlider2Changed", value)
        }
        
        @objc func handleSlider3Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            debugPrint("handleSlider3Changed", value)
        }
        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if self.addedModel {
                view.scene.removeAnchor(self.model)
                self.addedModel = false
                // debugPrint("Removed mansion from ", model.position)
            } else {
                self.model = self.loadedModel.clone(recursive: true)
                #if !targetEnvironment(simulator)
                self.model.setTransformMatrix(simd_float4x4(1.0), relativeTo: nil)
                self.model.position = focusEntity.position
                #endif
                handleButton1Pressed(Notification(name: Notification.Name("")))
                view.scene.addAnchor(self.model)
                self.addedModel = true
//                let mtc = model.transform.matrix.columns
//                let matc = model.anchor!.transform.matrix.columns
//                let map = model.anchor!.position
//                debugPrint(String(format: "focusEntity.position: (%.2f, %.2f, %.2f)", focusEntity.position.x, focusEntity.position.y, focusEntity.position.z))
//                debugPrint(String(format: "Added mansion at (%.2f,%.2f,%.2f) with rot=%.2f", model.position.x, model.position.y, model.position.z, model.transform.rotation.angle))
//                debugPrint(String(format: "anchor.position: (%.2f, %.2f, %.2f)", map.x, map.y, map.z))
//                debugPrint(String(format: "anchor.transform.matrix: [ [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f] ]",
//                    matc.0.x, matc.0.y, matc.0.z, matc.0.w,
//                    matc.1.x, matc.1.y, matc.1.z, matc.1.w,
//                    matc.2.x, matc.2.y, matc.2.z, matc.2.w,
//                    matc.3.x, matc.3.y, matc.3.z, matc.3.w))
//                debugPrint(String(format: "transform.matrix: [ [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f], [%.2f, %.2f, %.2f, %.2f] ]",
//                    mtc.0.x, mtc.0.y, mtc.0.z, mtc.0.w,
//                    mtc.1.x, mtc.1.y, mtc.1.z, mtc.1.w,
//                    mtc.2.x, mtc.2.y, mtc.2.z, mtc.2.w,
//                    mtc.3.x, mtc.3.y, mtc.3.z, mtc.3.w))
            }
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
