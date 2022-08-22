//
//  MainARView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 28.04.22.
//

import UIKit
import SwiftUI
import ARKit
import Combine // Cancellable
import RealityKit
import FocusEntity

import Foundation
import MetalKit

extension MainARView: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //        // check if found anchors are Plane Anchors
        //        let planeAnchors = anchors.map { $0 as! ARPlaneAnchor }
        //        for planeAnchor in planeAnchors {
        //            let planeEntity = PlaneEntity(with: planeAnchor)
        //            scene.anchors.append(planeEntity)
        //        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //        // Filter to ARPlaneAnchors only
        //        let planeAnchors = anchors.map { $0 as! ARPlaneAnchor }
        //
        //        // Take all IDs of already attached ARPlaneAnchors
        //        let scenePlaneAnchorsID = scene.anchors.map { $0.anchorIdentifier }
        //
        //        // Iterate through each updated ARPlaneAnchor
        //        for planeAnchor in planeAnchors {
        //            // Take id of updated anchor
        //            let id = planeAnchor.identifier
        //
        //            // Look for matching id, if matches, update the transform
        //            if scenePlaneAnchorsID.contains(id) {
        //                print("found!")
        //                let entityToUpdate = (scene.anchors.filter { $0.anchorIdentifier == id }).first
        //                if let a = entityToUpdate as? PlaneEntity {
        //                    print("plane entity")
        //                }
        //                if let b = entityToUpdate as? ARPlaneAnchor {
        //                    print("just plane anchor")
        //                }
        //                if let c = entityToUpdate as? ModelEntity {
        //                    print("model entity")
        //                }
        //            }
        //        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("session interruption ended")
    }
}

class MainARView: ARView {
    static let shared = MainARView()

    enum ShaderType {
        case metalShader, metalPerformanceShader, effectFilter
        var id: Self { self }
    }
    struct Shader: Equatable {
        static func == (lhs: MainARView.Shader, rhs: MainARView.Shader) -> Bool {
            return lhs.name == rhs.name && lhs.type == rhs.type
        }
        var name: String
        var type: ShaderType
        var mpsFunction: ((ARView.PostProcessContext) -> Void)?
        var mpsObject: ObjectMPS?
    }
    public var useShader = false
    
    enum PipelineTarget {
        case simulation, correction
        var id: Self { self }
    }
    
    private var device = MTLCreateSystemDefaultDevice()
    
    struct ComputePipelineState {
        var state: MTLComputePipelineState
        var threadsPerThreadgroup: MTLSize
        var threadgroupsPerGrid: MTLSize
    }
    private var computePipelineState: ComputePipelineState?
    private var computePipelineState_TEST: ComputePipelineState?
    
    // https://github.com/JohnCoates/Slate/blob/67ab3721eb954d7ac0568f6b546390ae3831df34/Source/Rendering/Filters/Abstract/FragmentFilter.swift
    private func setupComputePipeline(device: MTLDevice, context: ARView.PostProcessContext, targetTexture: MTLTexture, kernelName: String?) throws -> ComputePipelineState? {
        print("Load kernel \(String(describing: kernelName!))_kernel")
        guard let library = device.makeDefaultLibrary(),
              let kernelFunction = kernelName != nil ? library.makeFunction(name: "\(kernelName!)_kernel") : nil,
              let pipelineState = try? device.makeComputePipelineState(function: kernelFunction)
        else {
            assertionFailure()
            return nil
        }
        
        let computePipelineState = pipelineState
        let threadsPerThreadgroup = MTLSize(width: pipelineState.threadExecutionWidth,
                                            height: pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth,
                                            depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (targetTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                          height: (targetTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                          depth: 1)
        
        return ComputePipelineState(
            state: pipelineState,
            threadsPerThreadgroup: threadsPerThreadgroup,
            threadgroupsPerGrid: threadgroupsPerGrid
        )
    }
    
    private var shaderTargets: [PipelineTarget: [String]] = [:]
    
    private func createPostProcessShader(kernelName: String, arguments: [Float] = []) -> ((ARView.PostProcessContext) -> Void)? {
        computePipelineState = nil
        let initialTime = Date().timeIntervalSince1970
        // https://rozengain.medium.com/quick-realitykit-tutorial-custom-post-processing-b5275d9271b
        return { [weak self] context in
            guard let self = self,
                  let device = self.device
            else { return }
            
            if self.computePipelineState == nil {
                self.computePipelineState = try? self.setupComputePipeline(
                    device: device,
                    context: context,
                    targetTexture: context.targetColorTexture,
                    kernelName: kernelName
                )
            }

            //let renderPassDescriptor = MTLRenderPassDescriptor()
            //renderPassDescriptor.colorAttachments[0].texture = context.sourceColorTexture
            //renderPassDescriptor.colorAttachments[0].texture = context.targetColorTexture
            //renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.0, 1.0)
            //renderPassDescriptor.colorAttachments[0].loadAction = .clear
            //renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            guard let computePipelineState = self.computePipelineState,
                  let encoder = context.commandBuffer.makeComputeCommandEncoder()
            else { return }

            var allArguments: [Float] = [Float(Date().timeIntervalSince1970 - initialTime)]
            allArguments.append(contentsOf: arguments)
            //var arguments: [Float] = [ Float(Date().timeIntervalSince1970 - initialTime) ]
            let argumentBuffer = device.makeBuffer(bytes: &allArguments, length: MemoryLayout<Float>.size * allArguments.count)
            
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.pixelFormat = context.sourceColorTexture.pixelFormat
            textureDescriptor.width = context.sourceColorTexture.width
            textureDescriptor.height = context.sourceColorTexture.height
            textureDescriptor.usage = [ .shaderWrite, .shaderRead ]
            //let simulationTexture = device.makeTexture(descriptor: textureDescriptor)
                     
            encoder.pushDebugGroup("\(kernelName) compute pipeline")
            encoder.setComputePipelineState(computePipelineState.state)
            encoder.setTexture(context.sourceColorTexture, index: 0)
            //encoder.setTexture(simulationTexture, index: 1)
            encoder.setTexture(context.targetColorTexture, index: 1)
            for i in (0 ..< allArguments.count) {
                //encoder.setBuffer(argumentBuffer, offset: 0, index: i)
                encoder.setBuffer(argumentBuffer, offset: MemoryLayout<Float>.size * i, index: i)
            }
            encoder.dispatchThreadgroups(
                computePipelineState.threadgroupsPerGrid,
                threadsPerThreadgroup: computePipelineState.threadsPerThreadgroup
            )
            
            
            // Vertex/Fragment tests
            // encoder.setRenderPipelineState(renderPipelineState)
            //encoder.setVertexTexture(context.sourceColorTexture, index: 0)
            // let widthData: [Int] = [ context.sourceColorTexture.width ]
            // let widthBuffer = device.makeBuffer(bytes: widthData, length: MemoryLayout<Int>.size)
            // encoder.setVertexBuffer(widthBuffer, offset: 0, index: 0)
            // encoder.setFragmentTexture(context.sourceColorTexture, index: 0)
            
            encoder.popDebugGroup()
            
            encoder.endEncoding()
        }
    }
    
    private func createMetalPerformanceShader(mpsFunction: ((ARView.PostProcessContext) -> Void)?) -> ((ARView.PostProcessContext) -> Void)? {
        return mpsFunction
    }
    
    private func createMetalPerformanceShader(mpsObject: ObjectMPS) -> ((ARView.PostProcessContext) -> Void)? {
        return mpsObject.process
    }
    
    /*func clearShaders(target: PipelineTarget? = nil) {
        if target == nil {
            // Clear all
        }
        
        if target == .simulation {
            
        }
        else if target == .correction {
            
        }
    }*/
    
    struct PostProcessInfo {
        var name: String
        var target: PipelineTarget
        var callback: ((ARView.PostProcessContext) -> Void) = {_ in }
    }
    private var postProcessInfos: [PostProcessInfo] = []

    
    private func createPipeline() {
        if postProcessInfos.count == 0 {
            renderCallbacks.postProcess = nil
            return
        }
        
        renderCallbacks.postProcess = ((ARView.PostProcessContext) -> Void)? {context in
            // Simulation
            for info in self.postProcessInfos {
                if info.target == .simulation {
                    info.callback(context)
                }
            }
            // Correction
            for info in self.postProcessInfos {
                if info.target == .correction {
                    info.callback(context)
                }
            }
        }
    }
    
    func disableShader(target: PipelineTarget, name: String? = nil) {
        for (index, info) in postProcessInfos.enumerated() {
            if info.target == target && (name == nil || info.name == name) {
                self.postProcessInfos.remove(at: index)
            }
        }
        
        createPipeline()
    }
    
    func enableShader(target: PipelineTarget, shader: Shader? = nil, arguments: [Float]? = nil) {
        if shader == nil {
            renderCallbacks.postProcess = nil
            return
        }
        
        // TODO: Optimization later
        // if renderCallbacks.postProcess != nil && activeShader == shader { return }
        
        var postProcessInfo: PostProcessInfo = PostProcessInfo(name: shader!.name, target: target)
        
        // TODO: Special logic, only one simulation shader is possible and, as of now, only one correction shader too!
        for info in self.postProcessInfos {
            if info.target == target {
                disableShader(target: target)
            }
        }
        
        switch shader!.type {
        case .metalShader:
            guard let callback = createPostProcessShader(kernelName: shader!.name, arguments: arguments ?? []) else { return }
            postProcessInfo.callback = callback
            
        case .metalPerformanceShader:
            if shader!.mpsFunction != nil {
                guard let callback = createMetalPerformanceShader(mpsFunction: shader!.mpsFunction!) else { return }
                postProcessInfo.callback = callback
            } else if shader!.mpsObject != nil {
                guard let callback = createMetalPerformanceShader(mpsObject: shader!.mpsObject!) else { return }
                postProcessInfo.callback = callback
            }
        
        case .effectFilter: fallthrough
        default: return
        }
        
        postProcessInfos.append(postProcessInfo)
        
        createPipeline()
    }
    
    func setupConfiguration() {
        environment.sceneUnderstanding.options = []
        //environment.sceneUnderstanding.options.insert(.physics)
        //environment.sceneUnderstanding.options.insert(.occlusion)
        //environment.background = Environment.Background.color(.black.withAlphaComponent(0.0))
        
        debugOptions = [
//            .showFeaturePoints,
//            .showAnchorOrigins,
//            .showAnchorGeometry,
//            .showPhysics,
//            .showSceneUnderstanding,
//            .showWorldOrigin
        ]
        
        // For performance, disable render options that are not required for this app.
//        renderOptions = [
//            .disableAutomaticLighting, // deprecated
//            .disableGroundingShadows,
//            .disableMotionBlur,
//            //.disableDepthOfField, // we definitely need this
//            .disableHDR,
//            //.disableFaceOcclusions, // deprecated
//            .disablePersonOcclusion,
//            .disableAREnvironmentLighting,
//            .disableFaceMesh
//        ]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .meshWithClassification
        //configuration.environmentTexturing = .automatic

        session.run(configuration)
    }
    
    func setupDummyScene() {
        let coords = [
            SIMD3<Float>(0.0, 0.0, 1.0),
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(-1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 0.0, -1.0),
        ]
        for coord in coords {
            let box = MeshResource.generateBox(size: 0.2)
            let material = SimpleMaterial(color: .green, isMetallic: true)
            let entity = ModelEntity(mesh: box, materials: [material])
            let ar = AnchorEntity()
            ar.position = coord
            ar.addChild(entity)
            scene.addAnchor(ar)
        }
    }
    
    func resetSession() {
        let configuration = session.configuration?.copy() as! ARConfiguration
        session.pause()
        /*scene.rootNode.enumerateChildNodes { (node, stop) in
            node.removeFromParentNode()
        }*/
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
    
        //setupDummyScene()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}
