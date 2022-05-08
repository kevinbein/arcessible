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
    
    @Binding var frame: ARFrame?
    
    func makeUIView(context: Context) -> ARView {
        let arView = MainARView.shared
        
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
        arView.addGestureRecognizer(
            UIPinchGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePinch)
            )
        )
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(frame: _frame)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        @Binding var frame: ARFrame?
        
        weak var view: MainARView?
        
        var model: AccessibleModel = AccessibleModel()
        var anchor: AnchorEntity?
        var addedModel = false
        var focusEntity: FocusEntity?

        init(frame: Binding<ARFrame?>) {
            _frame = frame
            
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
        
        let context = CIContext()
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            self.frame = frame
        }
        
        @objc func handleButton1Pressed(_ notification: Notification) {
            debugPrint("handleButton1Pressed")
        }
        
        @objc func handleButton2Pressed(_ notification: Notification) {
            debugPrint("handleButton2Pressed")
        }
        
        @objc func handleButton3Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.resetSession()
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
                view.scene.removeAnchor(self.anchor!)
                model.reset()
                self.addedModel = false
            } else {
                if (self.anchor != nil) {
                    view.scene.removeAnchor(self.anchor!)
                }
#if !targetEnvironment(simulator)
                let anchor = AnchorEntity(plane: .horizontal)
                anchor.position = focusEntity.position
                view.scene.addAnchor(anchor)
                guard let model = AccessibleModel.load(named: "mansion") else {
                    fatalError("Failed loading model 'mansion'")
                }
                self.model = model
                anchor.addChild(model)
                self.addedModel = true
                self.anchor = anchor
#endif
            }
        }
        
        var panTranslation: CGPoint?
        @objc func handlePan(sender: UIPanGestureRecognizer) {
            let translation = sender.translation(in: self.view)
            if sender.state == .began {
                panTranslation = translation
            } else if sender.state == .changed {
                panTranslation = panTranslation ?? translation
                let degrees = -1.0 * Float(panTranslation!.x - translation.x)
                self.model.rotate(degrees: degrees)
                panTranslation = translation
            } else if sender.state != .possible {
                panTranslation = nil
            }
        }
        
        var pinchScale: CGFloat?
        @objc func handlePinch(sender: UIPinchGestureRecognizer) {
            let scale = sender.scale
            if sender.state == .began {
                pinchScale = scale
            } else if sender.state == .changed {
                pinchScale = pinchScale ?? scale
                let degrees = 1.0 - Float(pinchScale! - scale)
                self.model.scale(factor: degrees)
                pinchScale = scale
            } else if sender.state != .possible {
                pinchScale = nil
            }
        }
    }
}
