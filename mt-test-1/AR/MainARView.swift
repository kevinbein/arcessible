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
    class ShaderOption {
        
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
    private var activeShader: Shader?
    
    private var device = MTLCreateSystemDefaultDevice()
    private var computePipelineState: MTLComputePipelineState?
    private var threadsPerThreadgroup = MTLSize()
    private var threadgroupsPerGrid = MTLSize()
    
    // https://github.com/JohnCoates/Slate/blob/67ab3721eb954d7ac0568f6b546390ae3831df34/Source/Rendering/Filters/Abstract/FragmentFilter.swift
    private func setupComputePipeline(device: MTLDevice, context: ARView.PostProcessContext, targetTexture: MTLTexture, kernelName: String?) throws {
        debugPrint("Load kernel \(kernelName)_kernel")
        guard let library = device.makeDefaultLibrary(),
              let kernelFunction = kernelName != nil ? library.makeFunction(name: "\(kernelName!)_kernel") : nil,
              let pipelineState = try? device.makeComputePipelineState(function: kernelFunction)
        else {
            assertionFailure()
            return
        }
        
        computePipelineState = pipelineState
        threadsPerThreadgroup = MTLSize(width: pipelineState.threadExecutionWidth,
                                        height: pipelineState.maxTotalThreadsPerThreadgroup / pipelineState.threadExecutionWidth,
                                        depth: 1)
        threadgroupsPerGrid = MTLSize(width: (targetTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                      height: (targetTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                      depth: 1)
    }
    
    fileprivate func enablePostProcessShader(kernelName: String) {
        computePipelineState = nil
        // https://rozengain.medium.com/quick-realitykit-tutorial-custom-post-processing-b5275d9271b
        renderCallbacks.postProcess = { [weak self] context in
            guard let self = self,
                  let device = self.device
            else { return }
            
            if self.computePipelineState == nil {
                try? self.setupComputePipeline(
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

            encoder.pushDebugGroup("\(kernelName) compute pipeline")
            encoder.setComputePipelineState(computePipelineState)
            encoder.setTexture(context.sourceColorTexture, index: 0)
            encoder.setTexture(context.targetColorTexture, index: 1)
            encoder.dispatchThreadgroups(self.threadgroupsPerGrid, threadsPerThreadgroup: self.threadsPerThreadgroup)
            
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
    
    fileprivate func enableMetalPerformanceShader(mpsFunction: ((ARView.PostProcessContext) -> Void)?) {
        renderCallbacks.postProcess = mpsFunction
    }
    fileprivate func enableMetalPerformanceShader(mpsObject: ObjectMPS) {
        renderCallbacks.postProcess = mpsObject.process
    }
    
    func enableShader(enabled: Bool = true, shader: Shader? = nil) {
        if enabled == false || shader == nil {
            renderCallbacks.postProcess = nil
            return
        }
        
        // TODO: Optimization later
        // if renderCallbacks.postProcess != nil && activeShader == shader { return }
        
        activeShader = shader
        
        switch shader!.type {
            case .metalShader:
                enablePostProcessShader(kernelName: shader!.name)
            
            case .metalPerformanceShader:
                if shader!.mpsFunction != nil {
                    enableMetalPerformanceShader(mpsFunction: shader!.mpsFunction!)
                } else if shader!.mpsObject != nil {
                    enableMetalPerformanceShader(mpsObject: shader!.mpsObject!)
                }
            
            case .effectFilter: fallthrough
            
            default: return
        }
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
