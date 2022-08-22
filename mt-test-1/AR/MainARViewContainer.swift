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
        var activeModelName: String = "mansion"
        var anchor: AnchorEntity?
        var addedModel = false
        var focusEntity: FocusEntity?
        
        var activeSimulationName: String = "none"
        
        var activeCorrectionName: String = "none"

        init(frame: Binding<ARFrame?>) {
            _frame = frame
            
            super.init()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonResetSessionPressed(_:)), name: Notification.Name("ButtonResetSessionPressed"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerModelChanged(_:)), name: Notification.Name("PickerModelChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerSimulationChanged(_:)), name: Notification.Name("PickerSimulationChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerCorrectionChanged(_:)), name: Notification.Name("PickerCorrectionChanged"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderBlurringSigmaChanged(_:)), name: Notification.Name("SliderBlurringSigmaChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderProtanomalyPhiChanged(_:)), name: Notification.Name("SliderProtanomalyPhiChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderDeuteranomalyPhiChanged(_:)), name: Notification.Name("SliderDeuteranomalyPhiChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderTritanomalyPhiChanged(_:)), name: Notification.Name("SliderTritanomalyPhiChanged"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleToggle1Changed(_:)), name: Notification.Name("Toggle1Changed"), object: nil)
        }
        
        private func loadFocusEntity() {
            guard let view = self.view, self.focusEntity == nil else { return }
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        private func destroyFocusEntity() {
#if !targetEnvironment(simulator)
            self.focusEntity?.destroy()
            self.focusEntity = nil
#endif
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            loadFocusEntity()
        }
        
        let context = CIContext()
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            self.frame = frame
        }
        
        @objc func handleButtonResetSessionPressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.resetSession()
            debugPrint("handleButtonResetSessionPressed")
        }
        
        @objc func handlePickerModelChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            activeModelName = value
            debugPrint("handlePickerModelChanged", value)
        }
        @objc func handlePickerSimulationChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            activeSimulationName = value
            debugPrint("handlePickerSimulationChanged", value)
            
            guard let view = self.view else { return }
            
            switch activeSimulationName {
                
            case "blurring":
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()))
                
            case "floaters":
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "floatersDots", type: .metalShader))
                
            case "glaucoma":
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "glaucoma", type: .metalShader))
                
            case "macularDegeneration":
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "macularDegeneration", type: .metalShader))
                
            case "protanomaly":
                let type: Float = 0.0;
                let args: [Float] = [ type, 1.0 ];
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
                
            case "deuteranomaly":
                let type: Float = 1.0;
                let args: [Float] = [ type, 1.0 ];
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
                
            case "tritanomaly":
                let type: Float = 2.0;
                let args: [Float] = [ type, 1.0 ];
                view.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
                
            case "none":
                fallthrough
            default:
                view.disableShader(target: .simulation)
                
            }
        }
        @objc func handlePickerCorrectionChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            activeCorrectionName = value
            debugPrint("handlePickerCorrectionlChanged", value)
        }
        
        @objc func handleSliderBlurringSigmaChanged(_ notification: Notification) {
            guard let view = self.view, let value = notification.userInfo?["value"] as? Double else { return }
            let mps = GaussianBlurMPS(sigma: Float(value))
            view.enableShader(target: .simulation, shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: mps))
            debugPrint("handleSliderBlurringSigmaChanged", value)
        }
        @objc func handleSliderProtanomalyPhiChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 0.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view!.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
            debugPrint("handleSliderProtanomalyPhiChanged", Float(phi))
        }
        @objc func handleSliderDeuteranomalyPhiChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 1.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view!.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
            debugPrint("handleSliderDeuteranomalyPhiChanged", Float(phi))
        }
        @objc func handleSliderTritanomalyPhiChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 2.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view!.enableShader(target: .simulation, shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args)
            debugPrint("handleSliderTritanomalyPhiChanged", Float(phi))
        }
        
        
        // Old
        /*@objc func handleButton1Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.cameraFeed()
            view.enableShader(enabled: false)
            debugPrint("handleButton1Pressed")
        }
        
        @objc func handleButton2Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.color(.black.withAlphaComponent(0.0))
            view.enableShader(enabled: false)
            debugPrint("handleButton2Pressed")
        }
        
        @objc func handleButton3Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.cameraFeed()
            view.enableShader(enabled: true, shader: MainARView.Shader(name: "inverseColor", type: .metalShader))
            debugPrint("handleButton3Pressed")
        }
        
        @objc func handleButton4Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.resetSession()
            debugPrint("handleButton4Pressed")
        }
        
        // Blurring
        @objc func handleButton5Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.enableShader(enabled: true, shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()))
            debugPrint("handleButton5Pressed")
        }
        
        @objc func handleButton6Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.enableShader(enabled: true, shader: MainARView.Shader(name: "floatersDots", type: .metalShader))
            debugPrint("handleButton6Pressed")
        }
        
        @objc func handleButton7Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.enableShader(enabled: true, shader: MainARView.Shader(name: "floaters", type: .metalShader))
            debugPrint("handleButton7Pressed")
        }
        
        @objc func handleButton8Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            //view.enableShader(enabled: true, shader: MainARView.Shader(name: "macularDegeneration", type: .metalShader))
            view.enableShader(enabled: true, shader: MainARView.Shader(name: "glaucoma", type: .metalShader))
            debugPrint("handleButton8Pressed")
        }
        */
        
        @objc func handleSlider3Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            debugPrint("handleSlider3Changed", value)
        }
        
        @objc func handleToggle1Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Bool else { return }
            guard let view = self.view else { return }
            if !value {
                view.debugOptions = []
                return
            }
            view.debugOptions = [
                .showFeaturePoints,
                .showAnchorOrigins,
                .showAnchorGeometry,
//                .showPhysics,
                .showSceneUnderstanding,
                .showWorldOrigin
            ]
            debugPrint("handleToggle1Changed", value)
        }
        
        // User Controls
        
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }
            
            if self.addedModel {
                view.scene.removeAnchor(self.anchor!)
                loadFocusEntity()
                model.reset()
                self.addedModel = false
            } else {
                if (self.anchor != nil) {
                    view.scene.removeAnchor(self.anchor!)
                }
#if !targetEnvironment(simulator)
                var anchor: AnchorEntity
                if activeModelName == "braunbaerVertical" {
                    anchor = AnchorEntity(plane: .vertical)
                } else {
                    anchor = AnchorEntity(plane: .horizontal)
                }
                anchor.position = focusEntity.position
                guard let model = AccessibleModel.load(named: activeModelName) else {
                    fatalError("Failed loading model '\(activeModelName)'")
                }
                anchor.addChild(model)
                view.scene.addAnchor(anchor)
                destroyFocusEntity()
                self.model = model
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
