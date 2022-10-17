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
import GameplayKit

import Foundation
import MetalKit

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
    enum PipelineTarget {
        case simulation, correction
        var id: Self { self }
    }
    public struct ShaderDescriptor {
        var target: PipelineTarget
        var shader: Shader
        var arguments: [Float]
        var textures: [String]
    }
    
    private var device: MTLDevice!
    // private var metalLayer: CAMetalLayer!
    private var renderPipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var library: MTLLibrary!
    private var computePipelineState: MTLComputePipelineDescriptor!
    private var loadedTextures: [String:MTLTexture] = [:]
    private var postProcessCallbacks: [PipelineTarget:((ARView.PostProcessContext) -> Void)?] = [:]
    
    public var currentContext: PostProcessContext?
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
        
        setupRenderingProcess()
    }
    
    private func setupRenderingProcess() {
        renderCallbacks.prepareWithDevice = ((MTLDevice) -> Void)? { device in
            self.device = device
            guard let library = device.makeDefaultLibrary() else {
                fatalError()
            }
            self.library = library
            self.commandQueue = device.makeCommandQueue()
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
    
    private func generateNoiseTextureBuffer(width: Int, height: Int) -> [Float] {
        let w = Float(width)
        let h = Float(height)
        var noiseData = [Float](repeating: 0, count: width * height * 4 + (2 * height))
        let padding = 2
        
        let random = GKRandomSource()
        let gaussianGenerator = GKGaussianDistribution(randomSource: random, mean: 0.0, deviation: 1.0)
        let scale = sqrt(2.0 * min(w, h) * (2.0 / Float.pi))
        
        DispatchQueue.concurrentPerform(iterations: height * width) { index in
            // let index = yi * width + xi
            let y = Float(floor(Double(index / height)))
            let x = Float(index % width)
            
            let randX = gaussianGenerator.nextUniform()
            let randY = gaussianGenerator.nextUniform()
            
            let rx = floor(max(min(x + scale * randX, w - 1.0), 0.0))
            let ry = floor(max(min(y + scale * randY, h - 1.0), 0.0))
            
            noiseData[index * 4 + 0] = (rx + 0.5)
            noiseData[index * 4 + 1] = (ry + 0.5)
            noiseData[index * 4 + 2] = 1
            noiseData[index * 4 + 3] = 1
        }
        
        return noiseData
    }
    
    private func getTextureDescriptor() -> MTLTextureDescriptor{
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba32Float // context.sourceColorTexture.pixelFormat // bgra10_xr_srgb
        //textureDescriptor.width =  1172 + 2 // context.sourceColorTexture.width + 2
        textureDescriptor.width = 1170
        textureDescriptor.height = 2532// context.sourceColorTexture.height
        textureDescriptor.usage = [ .shaderWrite, .shaderRead ]
        return textureDescriptor
    }
    
    private func loadTextures(_ shaderDescriptor: ShaderDescriptor) {
        for name in shaderDescriptor.textures {
            if self.loadedTextures[name] != nil {
                continue
            }
            
            switch name {
            case "temp1": fallthrough
            case "temp2": fallthrough
            case "temp3": fallthrough
            case "temp4": fallthrough
            case "temp5":
                let textureDescriptor = getTextureDescriptor()
                guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
                    continue
                }
                loadedTextures[name] = texture
                
            case "noise":
                let textureDescriptor = getTextureDescriptor()
                let noiseData = self.generateNoiseTextureBuffer(width: textureDescriptor.width + 2, height: textureDescriptor.height)
                let noiseDataSize = noiseData.count * MemoryLayout.size(ofValue: noiseData[0])  + (MemoryLayout<Float32>.size * 4)
                let noiseBuffer = device.makeBuffer(bytes: noiseData, length: noiseDataSize)
                //let texture = noiseBuffer?.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: MemoryLayout<Float32>.size * textureDescriptor.width * 4 + (2 * MemoryLayout<Float32>.size * 4))
                let texture = noiseBuffer?.makeTexture(descriptor: textureDescriptor, offset: 0, bytesPerRow: MemoryLayout<Float32>.size * textureDescriptor.width * 4 + (2 * MemoryLayout<Float32>.size * 4))
                
                /*let textureUrl = Bundle.main.url(forResource: "noise", withExtension: "png")
                if textureUrl == nil {
                    continue
                }
                let loader = MTKTextureLoader(device: self.device)
                let texture = try! loader.newTexture(URL: textureUrl!)*/
                
                loadedTextures[name] = texture
                
            default:
                break
            }
        }
    }
    
    private func createPostProcess(shaderDescriptors shaders: [ShaderDescriptor]) -> ((ARView.PostProcessContext) -> Void)? {
        var computePipelineStates: [MTLComputePipelineState] = []
        for shaderDescriptor in shaders {
            // Load kernel function into the library
            guard let kernelFunction = self.library.makeFunction(name: "\(shaderDescriptor.shader.name)_kernel"),
                  let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
            else {
                return nil
            }
            computePipelineStates.append(computePipelineState)
            
            loadTextures(shaderDescriptor)
        }
        
        let initialTime = Date().timeIntervalSince1970
        
        return { context in
            var computePassDescriptor = MTLComputePassDescriptor()
            
            for (i, shaderDescriptor) in shaders.enumerated() {
                let computePipelineState = computePipelineStates[i]
                
                guard let encoder = context.commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else {
                    continue
                }
                encoder.setComputePipelineState(computePipelineState)
                encoder.setTexture(context.sourceColorTexture, index: 0)
                encoder.setTexture(context.targetColorTexture, index: 1)
                
                var allArguments: [Float] = [Float(Date().timeIntervalSince1970 - initialTime)]
                allArguments.append(contentsOf: shaderDescriptor.arguments)
                let argumentBuffer = context.device.makeBuffer(bytes: &allArguments, length: MemoryLayout<Float>.size * allArguments.count)
                for j in (0 ..< allArguments.count) {
                    encoder.setBuffer(argumentBuffer, offset: MemoryLayout<Float>.size * j, index: j)
                }
                
                for (j, name) in shaderDescriptor.textures.enumerated() {
                    if self.loadedTextures[name] != nil {
                        encoder.setTexture(self.loadedTextures[name], index: 2 + j)
                    }
                }
                
                let threadsPerThreadgroup = MTLSize(width: computePipelineState.threadExecutionWidth,
                                                    height: computePipelineState.maxTotalThreadsPerThreadgroup / computePipelineState.threadExecutionWidth,
                                                    depth: 1)
                let threadgroupsPerGrid = MTLSize(width: (context.targetColorTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                                   height: (context.targetColorTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                                  depth: 1)
                encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                encoder.endEncoding()
            }
            
            // commited by postprocess
            // context.commandBuffer.commit()
            
            self.currentContext = context
        }
    }
    
    private func createMetalPerformanceShader(mpsFunction: ((ARView.PostProcessContext) -> Void)?) -> ((ARView.PostProcessContext) -> Void)? {
        return mpsFunction
    }
    
    private func createMetalPerformanceShader(mpsObject: ObjectMPS) -> ((ARView.PostProcessContext) -> Void)? {
        return mpsObject.process
    }
    
    public func runShaders(shaders: [ShaderDescriptor]) {
        if shaders.isEmpty {
            return
        }
        
        if shaders[0].shader.type == .metalPerformanceShader {
            for shaderDescriptor in shaders {
                if shaderDescriptor.shader.mpsFunction != nil {
                    guard let callback = createMetalPerformanceShader(mpsFunction: shaderDescriptor.shader.mpsFunction!) else { return }
                    postProcessCallbacks[shaderDescriptor.target] = callback
                } else if shaderDescriptor.shader.mpsObject != nil {
                    guard let callback = createMetalPerformanceShader(mpsObject: shaderDescriptor.shader.mpsObject!) else { return }
                    postProcessCallbacks[shaderDescriptor.target] = callback
                }
            }
        }
        
        if shaders[0].shader.type == .metalShader {
            let callback = createPostProcess(shaderDescriptors: shaders)
            postProcessCallbacks[shaders[0].target] = callback
        }
        
        renderCallbacks.postProcess = { context in
            var context = context
            let correctionCallback = self.postProcessCallbacks[.correction]
            let simulationCallback = self.postProcessCallbacks[.simulation]
            if correctionCallback != nil {
                correctionCallback!!(context)
            }
            if correctionCallback != nil, simulationCallback != nil {
                context.sourceColorTexture = context.targetColorTexture
            }
            if simulationCallback != nil {
                simulationCallback!!(context)
            }
        }
    }
    
    public func stopShaders(target: PipelineTarget) {
        postProcessCallbacks[target] = nil
        if postProcessCallbacks[.simulation] == nil, postProcessCallbacks[.correction] == nil {
            renderCallbacks.postProcess = nil
        }
    }
    
    public func resetSession() {
        let configuration = session.configuration?.copy() as! ARConfiguration
        session.pause()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
}
