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
    
    static var focusEntity: FocusEntity?
    
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
        
        if ProcessInfo.processInfo.environment["SCHEME_TYPE"] == "replay" {
            ReplaySceneSetup.setupReplay(forRecording: ProjectSettings.replayScene)
        }
        
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
        var workMode: MainUIView.WorkMode = ProjectSettings.initialWorkMode

        var argumentStorage = [
            "hsbc": [ "hue": Float(0.0), "saturation": Float(0.5), "brightness": Float(0.5), "contrast": Float(0.5) ]
        ]
        
        init(frame: Binding<ARFrame?>) {
            _frame = frame
            
            super.init()
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleARViewInitialized(_:)), name: Notification.Name("ARViewInitialized"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleInitEvaluation(_:)), name: Notification.Name("EvaluationInit"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleStartEvaluation(_:)), name: Notification.Name("EvaluationStart"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleEndedEvaluation(_:)), name: Notification.Name("EvaluationEnded"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleAbortedEvaluation(_:)), name: Notification.Name("EvaluationAborted"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonResetSessionPressed(_:)), name: Notification.Name("ButtonResetSessionPressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonScreenshotPressed(_:)), name: Notification.Name("ButtonScreenshotPressed"), object: nil)
            // NotificationCenter.default.addObserver(self, selector: #selector(handleButtonStartEvaluationPressed(_:)), name: Notification.Name("ButtonStartEvaluationPressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonAbortEvaluationPressed(_:)), name: Notification.Name("ButtonAbortEvaluationPressed"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonPrintEvaluationLogPressed(_:)), name: Notification.Name("ButtonPrintEvaluationLogPressed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleButtonTestPressed(_:)), name: Notification.Name("ButtonTestPressed"), object: nil)

            
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerModelChanged(_:)), name: Notification.Name("PickerModelChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerSimulationChanged(_:)), name: Notification.Name("PickerSimulationChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerCorrectionChanged(_:)), name: Notification.Name("PickerCorrectionChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handlePickerEvaluationPresetChanged(_:)), name: Notification.Name("PickerEvaluationPresetChanged"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderBlurringSigmaChanged(_:)), name: Notification.Name("SliderBlurringSigmaChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderProtanomalyPhiChanged(_:)), name: Notification.Name("SliderProtanomalyPhiChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderDeuteranomalyPhiChanged(_:)), name: Notification.Name("SliderDeuteranomalyPhiChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderTritanomalyPhiChanged(_:)), name: Notification.Name("SliderTritanomalyPhiChanged"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSliderHBCSChanged(_:)), name: Notification.Name("SliderHSBCChanged"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleToggle1Changed(_:)), name: Notification.Name("Toggle1Changed"), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(handleWorkModeChanged(_:)), name: Notification.Name("WorkModeChange"), object: nil)
        }
        
        private func loadFocusEntity() {
            guard let view = self.view, MainARViewContainer.focusEntity == nil else { return }
            MainARViewContainer.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        private func destroyFocusEntity() {
#if !targetEnvironment(simulator)
            MainARViewContainer.focusEntity?.destroy()
            MainARViewContainer.focusEntity = nil
#endif
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            if workMode == .debug {
                //loadFocusEntity()
            }
        }
        
        let context = CIContext()
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            self.frame = frame
            guard let view = self.view else { return }
            view.updateFrameData(frame: frame)
            
            // Populate Scene if data is available in replay mode
            if ProcessInfo.processInfo.environment["SCHEME_TYPE"] == "replay" {
                if ReplaySceneSetup.sceneOptions[ProjectSettings.replayScene]?.hideUi == true {
                    destroyFocusEntity()
                }
                ReplaySceneSetup.renderSceneNext(forRecording: ProjectSettings.replayScene, frameNumber: view.currentFrameNumber, view: view)
            }
            
            let worldMappingStatus: String = { (_ status: ARFrame.WorldMappingStatus) -> String in
                switch status {
                case .extending: return "extending"
                case .limited: return "limited"
                case .mapped: return "mapped"
                case .notAvailable: return "notAvailable"
                default: return "<invalid value>"
                }
            }(frame.worldMappingStatus)
            
            let output = " WMP=\(worldMappingStatus), FP=\(String(describing: frame.rawFeaturePoints?.points.count))"
            let information = [
                "WMP": worldMappingStatus,
                "FN": view.currentFrameNumber,
                "FP": frame.rawFeaturePoints?.points.count, // gives Optional(n)
            ] as [String : Any]
            
            Log.uiPrint(key: "frameInformation", value: information)
        }
        
        @objc func handleARViewInitialized(_ notification: Notification) {
            loadFocusEntity()
            Log.print("arview init controller")
        }
        
        @objc func handleButtonResetSessionPressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.resetSession()
            Log.print("handleButtonResetSessionPressed")
        }
        
        @objc func handleButtonScreenshotPressed(_ notification: Notification) {
            guard let view = self.view else { return }
            //view.currentContext!.targetColorTexture.writeToSavedPhotosAlbum()
            view.currentContext!.targetColorTexture.saveImage()
            Log.print("handleButtonScreenshotPressed")
        }
        
        @objc func handlePickerEvaluationPresetChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            let activeEvaluationPreset = MainUIView.EvaluationPreset(rawValue: value)
            Log.print("MainARViewContainer: handlePickerEvaluationPresetChanged", value)
        }
        
        @objc func handlePickerModelChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            activeModelName = value
            Log.print("handlePickerModelChanged", value)
        }
        @objc func handlePickerSimulationChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            let activeSimulation = MainUIView.Simulation(rawValue: value)
            Log.print("handlePickerSimulationChanged", value)
            
            guard let view = self.view else { return }
            
            switch activeSimulation {
                
            case .blurring:
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()), arguments: [], textures: [])], pipelineTarget: .simulation))
                
            case .floaters:
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "floatersDots", type: .metalShader), arguments: [], textures: [])], pipelineTarget: .simulation))
                
            case .glaucoma:
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "glaucoma", type: .metalShader), arguments: [], textures: [])], pipelineTarget: .simulation))
                
            case .macularDegeneration:
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "macularDegeneration", type: .metalShader), arguments: [], textures: [])], pipelineTarget: .simulation))
                
            case .protanomaly:
                let type: Float = 0.0;
                let args: [Float] = [ type, 1.0 ];
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
                
            case .deuteranomaly:
                let type: Float = 1.0;
                let args: [Float] = [ type, 1.0 ];
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
                
            case .tritanomaly:
                let type: Float = 2.0;
                let args: [Float] = [ type, 1.0 ];
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
            
            // Not working! Needs full implementation
            //case .contrastCheck:
                //var shaders: [MainARView.ShaderDescriptor] = []
                
                // shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "imageMedian", type: .metalPerformanceShader, mpsObject: ImageMedianMPS()), arguments: [], textures: []))
                //view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .simulation, frameMode: .combined))
                
            case .none?:
                fallthrough
            default:
                view.stopShaders(target: .simulation)
            }
        }
        
        @objc func handlePickerCorrectionChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? String else { return }
            let activeCorrection = MainUIView.Correction(rawValue: value)
            Log.print("handlePickerCorrectionlChanged", value)
            
            guard let view = self.view else { return }
            
            switch activeCorrection {
            case .edgeEnhancement:
                var shaders: [MainARView.ShaderDescriptor] = []
                // Detect edges
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "sobel", type: .metalPerformanceShader, mpsObject: SobelMPS()), arguments: [], textures: []))
                // grey scale
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader, mpsObject: LaplacianMPS()), arguments: [ 0.0, 0.5, 0.5, 0.0, 0.0 ], textures: [], targetTexture: "detectedEdges"))
                // mix
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "edgeEnhancement", type: .metalShader), arguments: [], textures: ["detectedEdges", "g_startCombinedBackgroundAndModelTexture"]))
                view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction))
                
            case .daltonization:
                let type: Float = 1.0; // Deut
                let args: [Float] = [ type ];
                var shaders: [MainARView.ShaderDescriptor] = []
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep0", type: .metalShader), arguments: args, textures: []))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep1", type: .metalShader), arguments: args, textures: ["noise", "temp1"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep2", type: .metalShader), arguments: args, textures: ["temp1", "temp2"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep25", type: .metalShader), arguments: args, textures: ["temp2", "temp3"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep3", type: .metalShader), arguments: args, textures: ["temp3", "temp1", "temp2"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep4", type: .metalShader), arguments: args, textures: ["temp2", "temp4"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep5", type: .metalShader), arguments: args, textures: ["temp2", "temp4", "temp1", "temp3"]))
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "daltonizationStep6", type: .metalShader), arguments: args, textures: ["temp3"]))
                view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction))
                
            case .sobel:
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "sobel", type: .metalPerformanceShader, mpsObject: SobelMPS()), arguments: [], textures: [])], pipelineTarget: .correction))
                
            case .hsbc:
                guard let storage = argumentStorage["hsbc"],
                      let hue = storage["hue"],
                      let brightness = storage["brightness"],
                      let saturation = storage["saturation"],
                      let contrast = storage["contrast"]
                else { return }
                let args: [Float] = [ hue, brightness, saturation, contrast, 0.0 ]
                view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .correction))
                
            case .bgGrayscale:
                let hue: Float = 0.0
                let brightness: Float = 0.5
                let saturation: Float = 0.5
                let contrast: Float = 0.0
                let args: [Float] = [ hue, brightness, saturation, contrast, 1.0 ]
                var shaders: [MainARView.ShaderDescriptor] = []
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), frameTarget: .background, arguments: args, textures: []))
                view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .separate))
                
            case .bgDepth:
                let hue: Float = 0.0
                let brightness: Float = 0.5
                let saturation: Float = 0.5
                let contrast: Float = 0.0
                let args: [Float] = [ hue, brightness, saturation, contrast, 1.0 ]
                var shaders: [MainARView.ShaderDescriptor] = []
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "depth", type: .metalShader), frameTarget: .background, arguments: [ 0.0 ], textures: ["g_depthTexture"]))
                view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .separate))
                
            case .bgDepthBlurred:
                let hue: Float = 0.0
                let brightness: Float = 0.5
                let saturation: Float = 0.5
                let contrast: Float = 0.0
                let args: [Float] = [ hue, brightness, saturation, contrast, 1.0 ]
                var shaders: [MainARView.ShaderDescriptor] = []
                shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "backgroundBlur", type: .metalShader), frameTarget: .background, arguments: [], textures: ["g_depthTexture"]))
                view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .correction, frameMode: .separate))
                
            case .none?:
                fallthrough
            default:
                view.stopShaders(target: .correction)
            }
        }
        
        @objc func handleSliderBlurringSigmaChanged(_ notification: Notification) {
            guard let view = self.view, let value = notification.userInfo?["value"] as? Double else { return }
            let mps = GaussianBlurMPS(sigma: Float(value))
            view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: mps), arguments: [], textures: [])], pipelineTarget: .simulation))
            Log.print("handleSliderBlurringSigmaChanged", value)
        }
        @objc func handleSliderProtanomalyPhiChanged(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 0.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view!.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
            Log.print("handleSliderProtanomalyPhiChanged", Float(phi))
        }
        @objc func handleSliderDeuteranomalyPhiChanged(_ notification: Notification) {
            guard let view = self.view, let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 1.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
            Log.print("handleSliderDeuteranomalyPhiChanged", Float(phi))
        }
        @objc func handleSliderTritanomalyPhiChanged(_ notification: Notification) {
            guard let view = self.view, let value = notification.userInfo?["value"] as? Double else { return }
            let type: Float = 2.0;
            let phi = Float(value);
            let args: [Float] = [ type, phi ];
            view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
            Log.print("handleSliderTritanomalyPhiChanged", Float(phi))
        }
        @objc func handleSliderHBCSChanged(_ notification: Notification) {
            guard let view = self.view,
                  let values = notification.userInfo else { return }
            let hue = Float((values["hue"] as? Double)!)
            let saturation = Float((values["saturation"] as? Double)!)
            let brightness = Float((values["brightness"] as? Double)!)
            let contrast = Float((values["contrast"] as? Double)!)
            argumentStorage["hsbc"]!["hue"]        = hue
            argumentStorage["hsbc"]!["saturation"] = saturation
            argumentStorage["hsbc"]!["brightness"] = brightness
            argumentStorage["hsbc"]!["contrast"]   = contrast
            let args: [Float] = [ hue, saturation, brightness, contrast, 0.0 ]
            view.runShaders(chain: MainARView.ShaderChain(shaders: [MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), arguments: args, textures: [])], pipelineTarget: .simulation))
            Log.print("handleSliderHBCSChanged", args)
        }
        
        
        // Old
        /*@objc func handleButton1Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.cameraFeed()
            view.runShaders(enabled: false)
            Log.print("handleButton1Pressed")
        }
        
        @objc func handleButton2Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.color(.black.withAlphaComponent(0.0))
            view.runShaders(enabled: false)
            Log.print("handleButton2Pressed")
        }
        
        @objc func handleButton3Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.environment.background = ARView.Environment.Background.cameraFeed()
            view.runShaders(enabled: true, shader: MainARView.Shader(name: "inverseColor", type: .metalShader))
            Log.print("handleButton3Pressed")
        }
        
        @objc func handleButton4Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.resetSession()
            Log.print("handleButton4Pressed")
        }
        
        // Blurring
        @objc func handleButton5Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.runShaders(enabled: true, shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()))
            Log.print("handleButton5Pressed")
        }
        
        @objc func handleButton6Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.runShaders(enabled: true, shader: MainARView.Shader(name: "floatersDots", type: .metalShader))
            Log.print("handleButton6Pressed")
        }
        
        @objc func handleButton7Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            view.runShaders(enabled: true, shader: MainARView.Shader(name: "floaters", type: .metalShader))
            Log.print("handleButton7Pressed")
        }
        
        @objc func handleButton8Pressed(_ notification: Notification) {
            guard let view = self.view else { return }
            //view.runShaders(enabled: true, shader: MainARView.Shader(name: "macularDegeneration", type: .metalShader))
            view.runShaders(enabled: true, shader: MainARView.Shader(name: "glaucoma", type: .metalShader))
            Log.print("handleButton8Pressed")
        }
        */
        
        @objc func handleSlider3Changed(_ notification: Notification) {
            guard let value = notification.userInfo?["value"] as? Double else { return }
            Log.print("handleSlider3Changed", value)
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
            Log.print("handleToggle1Changed", value)
        }
        
        var evaluationSession: EvaluationSession?
        @objc func handleInitEvaluation(_ notification: Notification) {
            guard let view = self.view,
                  let values = notification.userInfo?["value"] as? [String]
            else {
                fatalError("Could not start evaluation session because view was empty or evaluationPreset or evaluationCandidateName is missing")
            }
            if values[1].count == 0 {
                return
            }
            let position = focusEntity?.position ?? [0,0,0]
            evaluationSession = EvaluationSession.create(view: view, atPosition: position, evaluationPreset: values[0], candidateName: values[1])
            Log.print("Evaluation initialized with scene '\(values[0])' for user '\(values[1])'")
        }
        
        @objc func handleStartEvaluation(_ notification: Notification) {
            guard let evaluationSession = self.evaluationSession else {
                fatalError("Starting evaluation session failed because evaluationSession object is not initialized")
            }
            evaluationSession.start()
            destroyFocusEntity()
            Log.print("Evaluation started")
        }
        
        @objc func handleEndedEvaluation(_ notification: Notification) {
            guard let evaluationSession = self.evaluationSession else {
                fatalError("Evaluation session ended but the object is nil")
            }
            evaluationSession.printEvaluationSession()
            loadFocusEntity()
            Log.print("Evaluation ended successfully")
        }
        
        @objc func handleAbortedEvaluation(_ notification: Notification) {
            guard let evaluationSession = self.evaluationSession else {
                fatalError("Evaluation session aborted but the object is nil")
            }
            loadFocusEntity()
            Log.print("Evaluation was aborted")
        }
        
        @objc func handleButtonAbortEvaluationPressed(_ notification: Notification) {
            guard let view = self.view,
                  let evaluationSession = self.evaluationSession
            else { return }
            
            evaluationSession.abort()
            self.evaluationSession = nil
            Log.print("Evaluation was aborted. Scene was removed.")
        }
        
        @objc func handleButtonPrintEvaluationLogPressed(_ notification: Notification) {
            EvaluationSession.printCompleteStorage()
        }
        
        @objc func handleButtonTestPressed(_ notification: Notification) {
            guard let view = self.view else { return }
            evaluationSession = EvaluationSession.create(
                view: view,
                atPosition: [0,0,0],
                evaluationPreset: MainUIView.EvaluationPreset.gameTight.rawValue,
                candidateName: "__test"
            )
            evaluationSession!.test()
        }
        
        @objc func handleWorkModeChanged(_ notification: Notification) {
            guard let view = self.view, let value = notification.userInfo?["value"] as? String else { return }
            self.workMode = MainUIView.WorkMode(rawValue: value)!
            
            //view.stopShaders(target: .correction)
            //view.stopShaders(target: .simulation)
            
            // Reset all first
            view.debugOptions.remove(.showStatistics)
            view.stopShaders(target: .correction)
            view.stopShaders(target: .simulation)
            loadFocusEntity()
            
            if self.workMode == .debug {
                NotificationCenter.default.post(name: Notification.Name("PipelineReload"), object: self)
            }
            else if self.workMode == .evaluation {
            }
            else if self.workMode == .statistics {
                view.debugOptions.insert(.showStatistics)
            }
            else if self.workMode == .populateScene {
            }
        }
        
        // User Controls
        
        fileprivate func handleTapPlaceModel() {
            guard let view = self.view, let focusEntity = MainARViewContainer.focusEntity else { return }
            
            if self.addedModel {
                view.scene.removeAnchor(self.anchor!)
                loadFocusEntity()
                model.reset()
                self.addedModel = false
                Log.print("Removed model")
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
                if activeModelName == "wuschel1" {
                    activeModelName = "wuschel1.usdz"
                }
                anchor.position = focusEntity.position
                UserDefaults.standard.set("\(focusEntity.position)", forKey: "LastModelPosition")
                guard let model = AccessibleModel.load(named: activeModelName) else {
                    fatalError("Failed loading model '\(activeModelName)'")
                }
                anchor.addChild(model)
                view.scene.addAnchor(anchor)
                destroyFocusEntity()
                self.model = model
                self.addedModel = true
                self.anchor = anchor
                Log.print("Placed model")
#endif
            }
        }
        
        fileprivate func handleTapDetectModel(from sender: UITapGestureRecognizer) {
            guard let view = self.view, let evaluationSession = self.evaluationSession else { return }
            
            let tapLocation: CGPoint = view.center // sender.location(in: view)
            var results: [CollisionCastHit]
            results = view.hitTest(tapLocation, query: .all)
            if results.first != nil { //, results.first?.entity.name != "Ground Plane" {
                let result = results.first!
                evaluationSession.hit(result)
            } else {
                evaluationSession.noHit()
            }
        }
        
        let populationModelNames = [
            //"populating.keypointWall",
            "populating.emptyWall",
            "populating.chair",
            "populating.shelf",
            "populating.broom",
            "populating.bin",
            "populating.stool",
            "populating.clock",
        ]
        var populationIndex = 0
        var populationPreviousObjectPosition: SIMD3<Float>? = nil
        fileprivate func handleTapPopulateScene(from sender: UITapGestureRecognizer) {
            guard let view = self.view, let focusEntity = MainARViewContainer.focusEntity else { return }
            
            // Reset storage if needed
            UserDefaults.standard.removeObject(forKey: "sceneSetup")
            
            if populationIndex >= populationModelNames.count {
                NotificationCenter.default.post(name: Notification.Name("VisualNotification"), object: self, userInfo: ["color": Color.red])
                return
            }
            
            // Add next object at position ...
            var anchor = AnchorEntity(plane: .horizontal)
            let position = focusEntity.position
            anchor.position = position
            
            let fullName = populationModelNames[populationIndex]
            let nameComponents = fullName.components(separatedBy: ".")
            let modelName = nameComponents[0]
            let sceneName = nameComponents[1]
            guard let model = AccessibleModel.load(named: modelName, scene: sceneName) else {
                fatalError("Failed loading model '\(fullName)'")
            }
            anchor.addChild(model)
            view.scene.addAnchor(anchor)
            
            let cameraPosition: SIMD3<Float> = [
                view.session.currentFrame!.camera.transform.columns.3.x,
                view.session.currentFrame!.camera.transform.columns.3.y,
                view.session.currentFrame!.camera.transform.columns.3.z
            ]
            let distanceToCamera = length(cameraPosition - position)
            let distanceToPreviousObject = populationPreviousObjectPosition != nil ? length(position - populationPreviousObjectPosition!) : -1.0;
            
            // ... and log it
            Log.print(String(view.currentFrameNumber), populationModelNames[populationIndex], String(describing: position), String(distanceToCamera), String(distanceToPreviousObject), saveTo: "sceneSetup")
            
            populationPreviousObjectPosition = position;
            populationIndex += 1
            
            // Just to show some response
            NotificationCenter.default.post(name: Notification.Name("VisualNotification"), object: self, userInfo: ["color": Color.blue])
        }
        
        @objc func handleTap(sender: UITapGestureRecognizer) {
            if workMode == .debug {
                handleTapPlaceModel()
            }
            else if workMode == .evaluation {
                handleTapDetectModel(from: sender)
            }
            else if workMode == .populateScene {
                handleTapPopulateScene(from: sender)
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
