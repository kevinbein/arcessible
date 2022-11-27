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
// import ARVideoKit
import Combine

class EvaluationSession {
    struct SessionData {
        var activeModel: AccessibleModel?
        var activeAnchor: AnchorEntity?
        var modelEntities: [ModelEntity]?
        
        enum SessionState {
            case unInitialized, started, inProgress, ended, aborted
            var id: Self { self }
        }
        var sessionState: SessionState = .unInitialized
        
        var startTime: DispatchTime?
        var endTime: DispatchTime?
        var intermediateTimes: [DispatchTime] = []
        var activeModelIndex: Int = 0
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
            Log.print("EvaluationSession: Evaluation Results for (\(id)):")
            Swift.print("")
            Swift.print("\tCandidate name:", candidateName)
            Swift.print("\tPreset:", evaluationPreset)
            Swift.print("\tMin distance:", evaluationMinDistance)
            Swift.print("\tIntermediate Times:")
            for time in self.intermediateTimes {
                Swift.print("\t\t", time.format(differenceTo: startTime))
            }
            Swift.print("\tTotal time:", duration)
            Swift.print("")
        }
    }
    var sessionData: SessionData?
    
    var view: MainARView?

    public static func create(view: MainARView, atPosition position: SIMD3<Float>, evaluationPreset: String, candidateName: String) -> EvaluationSession? {
        if evaluationPreset.count > 0, candidateName.count > 0 {
            return EvaluationSession(view: view, atPosition: position, evaluationPreset: evaluationPreset, candidateName: candidateName)
        }
        return nil
    }
    
    fileprivate init(view: MainARView, atPosition: SIMD3<Float> = [0, 0, 0], evaluationPreset: String, candidateName: String) {
        self.view = view
        self.sessionData = SessionData()
        self.sessionData?.evaluationPreset = evaluationPreset
        self.sessionData?.candidateName = candidateName
        self.sessionData?.sessionState = .started
        
        setupOptions()
        loadScene(atPosition: atPosition)
        loadShaders()
    }
    
    private func showModelEntities(_ show: Bool = true, entity: ModelEntity? = nil) {
        return 
        let factor: Float = 1000.0
        let scale = show ? SIMD3<Float>(repeating: factor) : SIMD3<Float>(repeating: 1 / factor)
        if entity != nil {
            entity!.scale *= scale
            //debugPrint("\(show ? "show" : "hide") model \(entity!.name)", show, scale)
            //debugPrint(entity!)
        } else {
            self.sessionData?.modelEntities?.forEach { modelEntity in
                modelEntity.scale *= scale
                //debugPrint("\(show ? "show" : "hide") model \(modelEntity.name)", show, scale)
                //debugPrint(modelEntity)
            }
        }
    }
    
    var collisionSubscriptions: [Cancellable] =  []
    var calibratedModelCount = 0
    private func calibrate() {
        guard let view = self.view,
              let modelEntities = self.sessionData?.modelEntities
        else { return }
        
        let timeNow = DispatchTime.now()
        Log.print("EvaluationSession: Calibration started")
        
        collisionSubscriptions.forEach { sub in sub.cancel() }
        collisionSubscriptions = []
        
        modelEntities.enumerated().forEach { (index, modelEntity)  in
            // Add physic parameters
            let physicsResource = PhysicsMaterialResource.generate(friction: 0, restitution: 0)
            let physicsComponent = PhysicsBodyComponent(
                shapes: [.generateBox(size: (modelEntity.model?.mesh.bounds.extents)!)],
                  mass: 20,         // in kilograms
              material: physicsResource,
                  mode: .dynamic
            )
            modelEntity.components[PhysicsBodyComponent.self] = physicsComponent
            
            // Register collision feedback handler
            collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self, on: modelEntity) { event in
                let groundPlane = event.entityB
                if groundPlane.name != "Ground Plane" {
                    return
                }
                
                // Stop once an item touches the ground plane (gravity pulls it down to have the objects correctly anchored
                let modelEntity = event.entityA
                //Log.print(modelEntity, modelEntity.components[PhysicsBodyComponent.self])
                if modelEntity.components.has(PhysicsBodyComponent.self) {
                    // This throws a critical thread exception??
                    //modelEntity.components.remove(PhysicsBodyComponent.self)
                    // Let's do it this way then ... might be cleaner anyway
                    var component = modelEntity.components[PhysicsBodyComponent.self] as! PhysicsBodyComponent
                    component.mode = .static
                    modelEntity.components[PhysicsBodyComponent.self] = component
                }
                
                Log.print("EvaluationSession: Calibrated (\(self.calibratedModelCount + 1) / \(modelEntities.count)", modelEntity.name)
                
                self.calibratedModelCount += 1
                if self.calibratedModelCount >= modelEntities.count {
                    Log.print("EvaluationSession: Calibration ended", timeNow.format(differenceTo: DispatchTime.now()))
                    self.collisionSubscriptions.removeAll()
                }
            })
        }
    }
    
    private func loadScene(atPosition position: SIMD3<Float>) {
        guard var sessionData = self.sessionData else { return }
        
        var anchor = AnchorEntity()
        anchor.position = position
        self.sessionData?.activeAnchor = anchor
        
        guard let allModels = AccessibleModel.load(named: "evaluation", scene: sessionData.evaluationPreset, generateCollisions: true)
        else {
            fatalError("EvaluationSession: Failed loading existing scene '\(sessionData.evaluationPreset)'")
        }
        self.sessionData?.activeModel = allModels
        
        // Find all models
        self.sessionData?.modelEntities = []
        for index in 0..<50 {
            // Find the model Entity
            guard let entity = allModels.findEntity(named: "evaluationModel\(index)") else { continue }
            var modelEntity = entity.findEntity(named: "simpBld_root") as? ModelEntity
            if modelEntity == nil {
                if let stylizedEntity = entity.findEntity(named: "stylized_lod0") {
                    modelEntity = stylizedEntity.children[0] as? ModelEntity
                    if modelEntity == nil {
                        continue
                    }
                } else {
                    continue
                }
            }
            self.sessionData?.modelEntities?.append(modelEntity!)
        }
        
        // Hide all of them (scale extremly down) so the user cannot see them
        showModelEntities(false)
        
        // Add them to the scene
        anchor.addChild(allModels)
        view?.scene.addAnchor(anchor)
        
        Log.print("EvaluationSession: Loaded existing scene '\(sessionData.evaluationPreset)'")
        
        calibrate()
        
        /*let cameraTransform = view?.session.currentFrame?.camera.transform
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
        }*/
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
            self.sessionData?.evaluationMinDistance = 1.0
            
        case .none:
            fallthrough
        case .some(_):
            break
        }
    }
    
    public func test() {
        Log.print("EvaluationSession: === Calibration Test START ===")
        
        //loadScene(atPosition: [0,0,0])
        
        Log.print("EvaluationSession: === Calibration Test END ===")
    }
    
    public func start() {
        self.sessionData?.startTime = DispatchTime.now()
        self.sessionData?.sessionState = .inProgress
        
        Log.print("EvaluationSession: start()")
        
        displayNext()
    }
    
    public func hit(_ hit: CollisionCastHit) {
        guard let entity = hit.entity as? ModelEntity else {
            NotificationCenter.default.post(name: Notification.Name("EvaluationHitFailure"), object: self, userInfo: ["status": "missed", "distance": hit.distance])
            return
        }
        
        let timeNow = DispatchTime.now()
        
        Log.print("EvaluationSession: Hit model '\(entity.name)' in distance \(hit.distance) after : \(self.sessionData?.startTime?.format(differenceTo: timeNow))")
        
        if hit.distance > self.sessionData!.evaluationMinDistance {
            NotificationCenter.default.post(name: Notification.Name("EvaluationHitFailure"), object: self, userInfo: ["status": "out-of-bounds", "distance": hit.distance])
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name("EvaluationHitSuccess"), object: self, userInfo: ["status": "hit", "distance": hit.distance])
        
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
        
        if sessionData.activeModelIndex >= sessionData.modelEntities!.count {
            self.sessionData?.activeModelIndex = 0
            end()
            return
        }
            
        // Hide all (during calibration, everything is already hidden)
        //if sessionData.activeModelIndex > 0 {
        //    showModelEntities(false)
        //}
        
        // Show the next active one
        showModelEntities(true, entity: sessionData.modelEntities![sessionData.activeModelIndex])
        
        Log.print("EvaluationSession: Display next child \(sessionData.activeModelIndex + 1) of \(sessionData.modelEntities!.count)")
        self.sessionData?.activeModelIndex += 1
        NotificationCenter.default.post(name: Notification.Name("EvaluationNext"), object: self)
        
        //let children = sessionData.activeModel?.anchor?.children[0].children[0].children
        //if sessionData.currentChildIndex >= children!.count {
        //if sessionData.currentChildIndex >= 1 {
            //self.sessionData?.currentChildIndex = 0
            //end()
            //return
        //}
        
        // Hide all
        //if sessionData.currentChildIndex > 0 {
        //    showModelEntities(false)
        //}
        /*for i in 0..<children!.count {
            //children![i].isEnabled = false
            children![i].setScale(SIMD3<Float>(repeating: 0.0001), relativeTo: children![i])
        }*/
        
        //children![sessionData.currentChildIndex].isEnabled = true
        //showModelEntities(true, entity: children![sessionData.currentChildIndex])
        //children![sessionData.currentChildIndex].setScale(SIMD3<Float>(repeating: 10000), relativeTo: children![sessionData.currentChildIndex])
        
        //Log.print("Display next child \(sessionData.currentChildIndex + 1) of \(children!.count)")
        //self.sessionData?.currentChildIndex += 1
        
        //NotificationCenter.default.post(name: Notification.Name("EvaluationNext"), object: self)
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
