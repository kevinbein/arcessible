//
//  Evaluation.swift
//  mt-test-1
//
//  Created by Kevin Bein on 19.11.22.
//

import Foundation
import Dispatch
import RealityKit
import ARKit
import ARVideoKit

extension DispatchTime: Identifiable {
    public var id: UInt64 { self.uptimeNanoseconds }
    
    func format(differenceTo: DispatchTime? = nil) -> Double {
        var nanoTime = self.uptimeNanoseconds
        if differenceTo != nil {
            nanoTime = max(differenceTo!.uptimeNanoseconds, self.uptimeNanoseconds)
                     - min(differenceTo!.uptimeNanoseconds, self.uptimeNanoseconds)
        }
        return Double(nanoTime) / 1_000_000_000
    }
}

class EvaluationSession {
    struct SessionData {
        var activeModel: AccessibleModel?
        var activeAnchor: AnchorEntity?
        
        enum SessionState {
            case unInitialized, started, ended, aborted
            var id: Self { self }
        }
        var sessionState: SessionState = .unInitialized
        
        var startTime: DispatchTime?
        var endTime: DispatchTime?
        var intermediateTimes: [DispatchTime] = []
        var currentChildIndex: Int = 0
        let id: String = UUID().uuidString
        var candidateName: String = ""
        var evaluationPreset: String = ""
        var evaluationMinDistance: Float = 10.0
        
        var duration: Double {
            guard let startTime = self.startTime,
                  let endTime = self.endTime
            else { return -1 }
            
            return startTime.format(differenceTo: endTime)
        }
        
        func save() {
            let serializedSession: Dictionary = [
                "id": id,
                "candidateName": candidateName,
                "startTime": startTime?.format() ?? -1,
                "endTime": endTime?.format() ?? -1,
                "duration": duration
            ] as [String : Any]
            
            guard var storageItems = UserDefaults.standard.dictionary(forKey: ProjectSettings.evaluationStorageKey) as? [[String : Any]] else {
                UserDefaults.standard.set([serializedSession], forKey: ProjectSettings.evaluationStorageKey)
                return
            }
            
            storageItems.append(serializedSession)
            UserDefaults.standard.set(storageItems, forKey: ProjectSettings.evaluationStorageKey)
        }
        
        func print() {
            Log.print("Evaluation Results for (\(id)):")
            Swift.print("")
            Swift.print("\tCandidate name:", candidateName) 
            Swift.print("\t", "Duration:", duration)
            for time in self.intermediateTimes {
                Swift.print("\t\t", "Intermediate timestamps:", time.format(differenceTo: startTime))
            }
            Swift.print("")
        }
    }
    var sessionData: SessionData?
    
    var view: MainARView?

    public static func create(view: MainARView, evaluationPreset: String, candidateName: String) -> EvaluationSession? {
        if evaluationPreset.count > 0, candidateName.count > 0 {
            return EvaluationSession(view: view, evaluationPreset: evaluationPreset, candidateName: candidateName)
        }
        return nil
    }
    
    fileprivate init(view: MainARView, evaluationPreset: String, candidateName: String) {
        self.view = view
        self.sessionData = SessionData()
        self.sessionData?.evaluationPreset = evaluationPreset
        self.sessionData?.candidateName = candidateName
    }
    
    fileprivate func loadScene_procedual() {
        let coords = [
            SIMD3<Float>(0.0, 0.0, 1.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(-1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, -1.0),
        ]
        for (i, coord) in coords.enumerated() {
            let box = MeshResource.generateBox(size: 0.2)
            //let material = SimpleMaterial(color: .green, isMetallic: true)
            let material = SimpleMaterial(color: .green, isMetallic: false)
            let entity = ModelEntity(mesh: box, materials: [material])
            entity.generateCollisionShapes(recursive: true)
            entity.name = "Cube \(i)"
            let ar = AnchorEntity()
            ar.position = coord
            Log.print("Model collision data: ", entity.collision?.shapes)
            ar.addChild(entity)
            view?.scene.addAnchor(ar)
        }
    }
    
    fileprivate func loadScene_game() {
        let coords = [
            SIMD3<Float>(0.0, 0.0, 1.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(-1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, -1.0),
        ]
        for (i, coord) in coords.enumerated() {
            let box = MeshResource.generateBox(size: 0.2)
            //let material = SimpleMaterial(color: .green, isMetallic: true)
            let material = SimpleMaterial(color: .green, isMetallic: false)
            let entity = ModelEntity(mesh: box, materials: [material])
            entity.generateCollisionShapes(recursive: true)
            entity.name = "Cube \(i)"
            let ar = AnchorEntity()
            ar.position = coord
            ar.addChild(entity)
            view?.scene.addAnchor(ar)
        }
    }
    
    fileprivate func loadGeneratedScene() {
    }
    
    fileprivate func loadExistingScene() {
    }
    
    private func loadScene(generatorName: String) {
    }
    
    private func loadScene(atPosition position: SIMD3<Float>) {
        guard var sessionData = self.sessionData else { return }
        
        var anchor: AnchorEntity
        
        // ARWorldTrackingConfiguration.PlaneDetection
        // anchor = AnchorEntity(target: .horizontal)
        anchor = AnchorEntity()
        
        anchor.position = position
        //anchor.position = [-0.74054515, -0.23813684, -0.7312187]
        guard let allModels = AccessibleModel.load(named: "evaluation", scene: sessionData.evaluationPreset, generateCollisions: true)
        else {
            fatalError("EvaluationSession: Failed loading existing scene '\(sessionData.evaluationPreset)'")
        }
        anchor.addChild(allModels)
        view?.scene.addAnchor(anchor)
        
        self.sessionData?.activeModel = allModels
        self.sessionData?.activeAnchor = anchor
        
        Log.print("EvaluationSession: Loaded existing scene '\(sessionData.evaluationPreset)'")
        
        let cameraTransform = view?.session.currentFrame?.camera.transform
        let cameraPosition = SIMD3<Float>(
            (cameraTransform?.columns.3.x)!,
            (cameraTransform?.columns.3.y)!,
            (cameraTransform?.columns.3.z)!
        )
        print("\tCamera position:", cameraPosition)
        print("\tScene position:", position)
        for entity in allModels.children[0].children[0].children {
            let modelEntity = entity as? ModelEntity
            let entityPosition = entity.transform.translation
            let entityCameraDistance = length(cameraPosition - entityPosition)
            let entitySceneDistance = length(position - entityPosition)
            print("\tEntity position:", entityPosition)
            print("\t\tDistance to camera", entityCameraDistance)
            print("\t\tDistance to scene", entitySceneDistance)
        }
    }
    
    private func loadShaders() {
        guard let view = self.view,
              let sessionData = self.sessionData
        else { return }
        
        switch sessionData.evaluationPreset {
        case "game":
            var shaders: [MainARView.ShaderDescriptor] = []
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gammaCorrection", type: .metalShader), frameTarget: .background, arguments: [], textures: []))
            let hue: Float = 0.0
            let brightness: Float = 0.5
            let saturation: Float = 0.5
            let contrast: Float = 0.0
            let args: [Float] = [ hue, brightness, saturation, contrast, 1.0 ]
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), frameTarget: .background, arguments: args, textures: []))
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .simulation, frameMode: .separate))
            
        default:
            var shaders: [MainARView.ShaderDescriptor] = []
            //shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gammaCorrection", type: .metalShader), frameTarget: .background, arguments: [], textures: []))
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .simulation, frameMode: .combined))
        }
        
    }
    
    private func setupOptions() {
        switch self.sessionData?.evaluationPreset {
        case "game":
            fallthrough
            
        case .none:
            fallthrough
        case .some(_):
            break
        }
    }
    
    public func start(atPosition: SIMD3<Float> = [0, 0, 0]) {
        self.sessionData?.startTime = DispatchTime.now()
        self.sessionData?.sessionState = .started
        
        setupOptions()
        loadScene(atPosition: atPosition)
        loadShaders()
        
        displayNext()
    }
    
    public func hit(_ hit: CollisionCastHit) {
        guard let entity = hit.entity as? ModelEntity else {
            NotificationCenter.default.post(name: Notification.Name("EvaluationHitFailure"), object: self)
            return
        }
        
        let timeNow = DispatchTime.now()
        
        Log.print("Hit model '\(entity.name)' in distance \(hit.distance) after : \(self.sessionData?.startTime?.format(differenceTo: timeNow))")
        
        if hit.distance > self.sessionData!.evaluationMinDistance {
            NotificationCenter.default.post(name: Notification.Name("EvaluationHitFailure"), object: self)
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("EvaluationHitSuccess"), object: self)
        
        self.sessionData?.intermediateTimes.append(timeNow)
        
        let newColorMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
        entity.model?.materials = [newColorMaterial]
        var scaleTransform = entity.transform
        scaleTransform.scale *= 0.01
        //scaleTransform.scale *= 0
        let rotationTransform = Transform(pitch: 0, yaw: 0, roll: .pi)
        // Stupid but works
        entity.move(to: scaleTransform, relativeTo: entity, duration: 0.5, timingFunction: .linear)
        entity.move(to: rotationTransform, relativeTo: entity, duration: 0.5, timingFunction: .linear)
        entity.move(to: rotationTransform, relativeTo: entity, duration: 0.5, timingFunction: .linear)
        entity.move(to: rotationTransform, relativeTo: entity, duration: 0.5, timingFunction: .linear)
        entity.move(to: rotationTransform, relativeTo: entity, duration: 0.5, timingFunction: .linear)
        
        Timer.scheduledTimer(withTimeInterval: 0.55, repeats: false) { timer in
            self.displayNext()
        }
    }
    
    private func displayNext() {
        guard let sessionData = self.sessionData else { return }
        
        let children = sessionData.activeModel?.anchor?.children[0].children[0].children
        if sessionData.currentChildIndex >= children!.count {
        //if sessionData.currentChildIndex >= 1 {
            self.sessionData?.currentChildIndex = 0
            end()
            return
        }
        
        // Hide all
        for i in 0..<children!.count {
            children![i].isEnabled = false
        }
        
        children![sessionData.currentChildIndex].isEnabled = true
        Log.print("Display next child \(sessionData.currentChildIndex + 1) of \(children!.count)")
        self.sessionData?.currentChildIndex += 1
        
        NotificationCenter.default.post(name: Notification.Name("EvaluationNext"), object: self)
    }
    
    private func end() {
        guard let sessionData = self.sessionData,
              let anchor = sessionData.activeAnchor
        else { return }
        
        view?.scene.removeAnchor(anchor)
        view?.stopShaders(target: .simulation)
        view?.stopShaders(target: .correction)
        
        // Correct the animation offset from displayNext()
        let timeNow = DispatchTime.now()
        self.sessionData?.endTime = DispatchTime(uptimeNanoseconds: timeNow.uptimeNanoseconds - UInt64(5.5e8))
        self.sessionData?.sessionState = .ended
        
        self.sessionData?.save()
        
        NotificationCenter.default.post(name: Notification.Name("EvaluationEnded"), object: self, userInfo: ["sessionData": self.sessionData!])
    }
    
    public func printEvaluationSession() {
        guard let sessionData = self.sessionData else { return }
        
        sessionData.print()
    }
    
    public func abort() {
        guard let sessionData = self.sessionData,
              let anchor = sessionData.activeAnchor
        else { return }
        
        view?.scene.removeAnchor(anchor)
        view?.stopShaders(target: .simulation)
        view?.stopShaders(target: .correction)
        
        self.sessionData?.sessionState = .aborted
        
        NotificationCenter.default.post(name: Notification.Name("EvaluationAborted"), object: self)
    }
    
    static func printCompleteStorage() {
        guard let storage = UserDefaults.standard.array(forKey: ProjectSettings.evaluationStorageKey) as? [[String : Any]] else { return }
        print(storage)
    }
}
