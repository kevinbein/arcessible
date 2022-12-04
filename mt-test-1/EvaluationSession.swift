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
        var modelEntitiesOptions: [[Any]] = []
        var evaluationRandomPositions: [Int]? = nil
        var evaluationRandomIndices: [Int]? = nil
        var evaluationMaxModelCount: Int? = nil
        
        enum SessionState {
            case unInitialized, started, inProgress, ended, aborted
            var id: Self { self }
        }
        var sessionState: SessionState = .unInitialized
        
        var startTime: DispatchTime?
        var endTime: DispatchTime?
        var intermediateTimes: [DispatchTime] = []
        var intermediateMisses: [Int] = []
        var intermediateMissDistances: [[Float]] = []
        var activeModelIndex: Int = 0
        let id: String = UUID().uuidString
        var candidateName: String = ""
        var evaluationPreset: String = ""
        var evaluationMinDistance: Float = 10.0
        
        var totalMisses: Int {
            return intermediateMisses.reduce(0, { $0 + $1 })
        }
        
        var averageIntermediateMissDistances: [Float] {
            return intermediateMissDistances.enumerated().map { (index, _) in
                if intermediateMissDistances[index].count == 0 {
                    return 0.0
                }
                return intermediateMissDistances[index].reduce(0.0, { $0 + $1 }) / Float(intermediateMissDistances[index].count)
            }
        }
        
        var averageMissDistance: Float {
            return averageIntermediateMissDistances.reduce(0.0, { $0 + $1 }) / Float(averageIntermediateMissDistances.count)
        }
        
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
            Swift.print("\tTotal misses:", self.totalMisses)
            Swift.print("\tIntermediate Misses:")
            for misses in self.intermediateMisses {
                Swift.print("\t\t", misses)
            }
            Swift.print("\tAverage Intermediate Miss Distances:")
            for missDistance in self.averageIntermediateMissDistances {
                Swift.print("\t\t", missDistance)
            }
            Swift.print("\tAverage Miss Distance:", self.averageMissDistance)
            Swift.print("\tIntermediate Miss Distances:", self.intermediateMissDistances)
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
        //return
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
              let modelEntities = self.sessionData?.modelEntities,
              let modelEntitiesOptions = self.sessionData?.modelEntitiesOptions
        else { return }
        
        let timeNow = DispatchTime.now()
        Log.print("EvaluationSession: Calibration started")
        
        collisionSubscriptions.forEach { sub in sub.cancel() }
        collisionSubscriptions = []
        
        Log.print("modelEntitiesOptions", modelEntitiesOptions)
        modelEntities.enumerated().forEach { (index, modelEntity)  in
            
            if modelEntitiesOptions[index][0] as! Bool {
                self.calibratedModelCount += 1
                Log.print("EvaluationSession: Model \(modelEntity.name) is fixed and stays in position.")
                return
            }
            
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
                
                Log.print("EvaluationSession: Calibrated (\(self.calibratedModelCount + 1) / \(modelEntities.count))", modelEntity.name)
                
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
        
        var sceneName = sessionData.evaluationPreset
        if sceneName == "gameContrast" || sceneName == "gameBackground" || sceneName == "gameBlurred" || sceneName == "gameCVD" || sceneName == "gameBlackWhite" {
            sceneName = "game"
        }
        
        guard let allModels = AccessibleModel.load(named: "evaluation", scene: sceneName, generateCollisions: true)
        else {
            fatalError("EvaluationSession: Failed loading existing scene '\(sessionData.evaluationPreset)'")
        }
        self.sessionData?.activeModel = allModels
        
        // Find all models
        self.sessionData?.modelEntities = []
        for index in 0..<50 {
            // Find the model Entity ... and possible variations with options
            var tmpEntity: Entity?
            var fixed = false
            
            tmpEntity = allModels.findEntity(named: "evaluationModel\(index)")
            if tmpEntity == nil {
                tmpEntity = allModels.findEntity(named: "evaluationModel\(index)_f")
                if tmpEntity == nil {
                    continue
                }
                Log.print("EvaluationSession: Set fixed=true for model evaluationModel\(index)_f")
                fixed = true
            }
            let entity = tmpEntity!
            
            var modelEntity = entity.findEntity(named: "simpBld_root") as? ModelEntity
            if modelEntity == nil {
                if let stylizedEntity = entity.findEntity(named: "stylized_lod0") {
                    modelEntity = stylizedEntity.children[0] as? ModelEntity
                    if modelEntity == nil {
                        continue
                    }
                }
                else if let realisticEntity = entity.findEntity(named: "realistic_lod0") {
                    modelEntity = realisticEntity.children[0] as? ModelEntity
                    if modelEntity == nil {
                        continue
                    }
                }
                else {
                    continue
                }
            }
            self.sessionData?.modelEntities?.append(modelEntity!)
            self.sessionData?.modelEntitiesOptions.append([fixed])
            Log.print("EvaluationSession: Placed model 'evaluationModel\(index)\(fixed ? "_f" : "")'")
            // Storing information in scale does only work for simple meshes. Then they are encrypted in scale directly in the model entity
            // For other objects we need to do the following:
            // Log.print(modelEntity!.name, modelEntity!.scale, modelEntity!.parent?.scale, modelEntity!.parent?.parent?.scale, modelEntity!.parent?.parent?.parent?.scale, modelEntity!.parent?.parent?.parent?.parent?.scale, modelEntity!.parent?.parent?.parent?.parent?.parent?.scale, modelEntity!.parent?.parent?.parent?.parent?.parent?.parent?.scale)
        }
        
        if self.sessionData?.modelEntities?.count == 0 {
            fatalError("No model entities found. Did you name all models within a scene like this: 'evaluationModelN' where N is a number from 0 to 49?")
        }
        
        // Shuffle entity positions
        if self.sessionData?.evaluationRandomPositions != nil {
            let randomPositions = self.sessionData!.evaluationRandomPositions!
            let originalPositions = allModels.children[0].children[0].children.map { $0.position }
            for index in 0..<randomPositions.count {
                let newPositionIndex = randomPositions[index]
                allModels.children[0].children[0].children[index].position = originalPositions[newPositionIndex]
            }
            Log.print("EvaluationSession: Randomized positions from", originalPositions, "to", allModels.children[0].children[0].children.map { $0.position })
        }
        
        // Swap order around
        if self.sessionData?.evaluationRandomIndices != nil {
            let indices = self.sessionData?.evaluationRandomIndices!
            var newEntryOrder: [ModelEntity] = []
            for index in 0..<indices!.count {
                let newIndex = self.sessionData!.evaluationRandomIndices![index]
                newEntryOrder.append(self.sessionData!.modelEntities![newIndex])
            }
            self.sessionData?.modelEntities = newEntryOrder
            Log.print("EvaluationSession: Randomized indices to", indices!)
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
            var simulationShaders: [MainARView.ShaderDescriptor] = []
            simulationShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: simulationShaders, pipelineTarget: .simulation, frameMode: .combined))
            
        case "gameCVD":
            var correctionShaders: [MainARView.ShaderDescriptor] = []
            let type: Float = 1.0;
            let args: [Float] = [ type, 1.0 ];
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "colorVisionDeficiency", type: .metalShader), arguments: args, textures: []))
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: correctionShaders, pipelineTarget: .simulation, frameMode: .combined))
            
        case "gameContrast":
            var correctionShaders: [MainARView.ShaderDescriptor] = []
            let hue: Float = 0.0
            let brightness: Float = 0.5
            let saturation: Float = 0.6
            let contrast: Float = 2.0
            let doGammaCorrection: Float = 1.0
            let args: [Float] = [ hue, brightness, saturation, contrast, doGammaCorrection ]
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), frameTarget: .background, arguments: args, textures: []))
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: correctionShaders, pipelineTarget: .correction, frameMode: .separate))
            
        case "gameBlackWhite":
            var correctionShaders: [MainARView.ShaderDescriptor] = []
            let hue: Float = 0.0
            let brightness: Float = 0.5
            let saturation: Float = 0.5
            let contrast: Float = 0.0
            let doGammaCorrection: Float = 1.0
            let args: [Float] = [ hue, brightness, saturation, contrast, doGammaCorrection ]
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), frameTarget: .combined, arguments: args, textures: []))
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: correctionShaders, pipelineTarget: .correction, frameMode: .combined))
            
        case "gameBackground":
            var correctionShaders: [MainARView.ShaderDescriptor] = []
            let hue: Float = 0.0
            let brightness: Float = 0.5
            let saturation: Float = 0.5
            let contrast: Float = 0.0
            let doGammaCorrection: Float = 1.0
            let args: [Float] = [ hue, brightness, saturation, contrast, doGammaCorrection ]
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "hsbc", type: .metalShader), frameTarget: .background, arguments: args, textures: []))
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: correctionShaders, pipelineTarget: .correction, frameMode: .separate))
            
            /*var simulationShaders: [MainARView.ShaderDescriptor] = []
            simulationShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: simulationShaders, pipelineTarget: .simulation, frameMode: .combined))*/
            
        case "gameBlurred":
            var correctionShaders: [MainARView.ShaderDescriptor] = []
            //correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()), frameTarget: .background, arguments: [], textures: []))
            
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gaussianBlur", type: .metalPerformanceShader, mpsObject: GaussianBlurMPS()), frameTarget: .background, arguments: [], textures: []))
            correctionShaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: correctionShaders, pipelineTarget: .correction, frameMode: .separate))
            
        default:
            var shaders: [MainARView.ShaderDescriptor] = []
            //shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "gammaCorrection", type: .metalShader), frameTarget: .background, arguments: [], textures: []))
            shaders.append(MainARView.ShaderDescriptor(shader: MainARView.Shader(name: "crosshair", type: .metalShader), frameTarget: .combined, arguments: [], textures: []))
            view.runShaders(chain: MainARView.ShaderChain(shaders: shaders, pipelineTarget: .simulation, frameMode: .combined))
        }
        
    }
    
    private func setupOptions() {
        switch self.sessionData?.evaluationPreset {
        case "gameTight":
            self.sessionData?.evaluationRandomPositions = [ 2, 0, 1 ]
            self.sessionData?.evaluationRandomIndices = [ 0, 1, 2 ]
            
        case "game":
            self.sessionData?.evaluationMinDistance = 0.7
            /*
             function shuffle(a) { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
             console.log(shuffle([...new Array(15)].map((k,i ) => i )));
            */
            self.sessionData?.evaluationMaxModelCount = 10
            //self.sessionData?.evaluationRandomPositions = [ 0, 8, 7, 14, 11, 6, 13, 10, 1, 12, 2, 3, 5, 4, 9 ]
            //self.sessionData?.evaluationRandomIndices = [ 0, 8, 7, 14, 11, 6, 13, 10, 1, 12, 2, 3, 5, 4, 9 ]
            
        case "gameBlackWhite":
            self.sessionData?.evaluationMaxModelCount = 10
            self.sessionData?.evaluationMinDistance = 0.7
            self.sessionData?.evaluationRandomIndices = [ 0, 10, 7, 14, 11, 6, 13, 1, 8, 12, 2, 3, 5, 4, 9 ]
            
        case "gameContrast":
            self.sessionData?.evaluationMaxModelCount = 10
            self.sessionData?.evaluationMinDistance = 0.7
            
        case "gameCVD":
            self.sessionData?.evaluationMaxModelCount = 10
            self.sessionData?.evaluationMinDistance = 0.7
            
        case "gameBackground":
            self.sessionData?.evaluationMaxModelCount = 10
            self.sessionData?.evaluationMinDistance = 0.7
            self.sessionData?.evaluationRandomPositions = [ 0, 10, 7, 14, 11, 6, 13, 1, 8, 12, 2, 3, 5, 4, 9 ]
            self.sessionData?.evaluationRandomIndices = [ 0, 10, 7, 14, 11, 6, 13, 1, 8, 12, 2, 3, 5, 4, 9 ]
            
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
        let count = self.sessionData?.modelEntities!.count
        self.sessionData?.intermediateMisses = [Int](repeating: 0, count: count!)
        self.sessionData?.intermediateMissDistances = [[Float]](repeating: [], count: count!)
        
        Log.print("EvaluationSession: start()")
        
        displayNext()
    }
    
    public func noHit(status: String = "failure", distance: Float = -1.0) {
        let index = self.sessionData!.activeModelIndex
        self.sessionData?.intermediateMisses[index - 1] += 1
        if status == "out-of-bounds", distance != -1.0 {
            self.sessionData?.intermediateMissDistances[index - 1].append(distance)
        }
        NotificationCenter.default.post(name: Notification.Name("EvaluationHitFailure"), object: self, userInfo: ["status": status, "distance": distance])
    }
    
    public func hit(_ hit: CollisionCastHit) {
        guard let entity = hit.entity as? ModelEntity else {
            noHit(status: "missed", distance: hit.distance)
            return
        }
        
        let timeNow = DispatchTime.now()
        
        Log.print("EvaluationSession: Hit model '\(entity.name)' in distance \(hit.distance) after : \(self.sessionData!.startTime!.format(differenceTo: timeNow))")
        
        if hit.distance > self.sessionData!.evaluationMinDistance {
            noHit(status: "out-of-bounds", distance: hit.distance)
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
        
        if sessionData.activeModelIndex >= sessionData.modelEntities!.count
            || (sessionData.evaluationMaxModelCount != nil && sessionData.activeModelIndex >= sessionData.evaluationMaxModelCount!)
        {
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
        
        var totalDisplayCount = sessionData.modelEntities!.count
        if sessionData.evaluationMaxModelCount != nil {
            totalDisplayCount = min(sessionData.modelEntities!.count, sessionData.evaluationMaxModelCount!)
        }
        Log.print("EvaluationSession: Display next child \(sessionData.activeModelIndex + 1) of \(totalDisplayCount)")
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
        Log.print(storage)
    }
}
