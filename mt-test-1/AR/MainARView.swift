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
import MetalPerformanceShaders

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
    enum FrameTarget {
        case full, background, foreground
        var id: Self { self }
    }
    public struct ShaderDescriptor {
        var pipelineTarget: PipelineTarget
        var shader: Shader
        var frameTarget: FrameTarget = .full
        var arguments: [Float]
        var textures: [String]
    }
    
    private var device: MTLDevice!
    private var ciContext: CIContext!
    // private var metalLayer: CAMetalLayer!
    private var renderPipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var library: MTLLibrary!
    private var globalComputePipelineStates: [String:MTLComputePipelineState] = [:]
    //private var computePipelineState: MTLComputePipelineDescriptor!
    private var loadedTextures: [String:MTLTexture] = [:]
    private var globalTextures: [String:MTLTexture] = [:]
    private var postProcessCallbacks: [PipelineTarget:((ARView.PostProcessContext) -> Void)?] = [:]
    
    private var rawFrame: ARFrame?
    private var backgroundFrameTexture: MTLTexture!
    private var combinedBackgroundAndModelTexture: MTLTexture!
    
    public var currentContext: PostProcessContext?
    
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
        setupRenderingProcess()
    }
    
    public func updateRawFrame(frame: ARFrame) {
        self.rawFrame = frame
    }
    
    private func setupRenderingProcess() {
        renderCallbacks.prepareWithDevice = ((MTLDevice) -> Void)? { device in
            self.device = device
            self.ciContext = CIContext(mtlDevice: device)
            guard let library = device.makeDefaultLibrary() else {
                fatalError()
            }
            self.library = library
            self.commandQueue = device.makeCommandQueue()
            
            self.loadGlobalShaders()
            self.loadGlobalTextures()
            
            NotificationCenter.default.post(name: Notification.Name("ARViewInitialized"), object: nil)
            print("renderCallbacks.prepareWithDevice: Finished")
        }
    }
    
    func setupConfiguration() {
        environment.sceneUnderstanding.options = []
        //environment.sceneUnderstanding.options.insert(.physics)
        //environment.sceneUnderstanding.options.insert(.occlusion)
        environment.background = Environment.Background.color(.black.withAlphaComponent(0.0))
        
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
        
        print("Loaded session configuration")
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
        textureDescriptor.width = 1170
        textureDescriptor.height = 2532// context.sourceColorTexture.height
        textureDescriptor.usage = [ .shaderWrite, .shaderRead ]
        return textureDescriptor
    }
    
    private func loadGlobalShaders() {
        for shaderName in ProjectSettings.globalShaders {
            guard let kernelFunction = self.library.makeFunction(name: "\(shaderName)_kernel"),
                  let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
            else { continue }
            globalComputePipelineStates[shaderName] = computePipelineState
            print("Loaded global kernel function \(shaderName)")
        }
    }
    
    private func loadGlobalTextures() {
        let loader = MTKTextureLoader(device: self.device)
        for (name, ext) in ProjectSettings.globalTextures {
            let textureUrl = Bundle.main.url(forResource: name, withExtension: ext)
            let fullName = "\(name).\(ext)"
            if textureUrl == nil {
                fatalError("Global texture \(fullName) could not be loaded!")
            }
            let texture = try! loader.newTexture(URL: textureUrl!)
            globalTextures[name] = texture
            print("Loaded global texture \(fullName)")
        }
        
        // Special textures
        var genericTextureDescriptor = getTextureDescriptor()
        
        guard let backgroundFrameTexture = device.makeTexture(descriptor: genericTextureDescriptor) else { return }
        self.backgroundFrameTexture = backgroundFrameTexture
        
        guard let combinedBackgroundAndModelTexture = device.makeTexture(descriptor: genericTextureDescriptor) else { return }
        self.combinedBackgroundAndModelTexture = combinedBackgroundAndModelTexture
    }
    
    private func loadTextures(_ shaderDescriptor: ShaderDescriptor) {
        // Create intermediate texture which stores the result from the correction step
        if self.loadedTextures["correctionTexture"] == nil {
            let textureDescriptor = getTextureDescriptor()
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
                assertionFailure()
                return
            }
            loadedTextures["correctionTexture"] = texture
        }
        
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
    
    private func capturedImageToMTLTexture(_ context: ARView.PostProcessContext, targetTexture: MTLTexture) {
        guard let frame = self.session.currentFrame else { return }
        let imageBuffer = frame.capturedImage
        let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
        var viewPort = self.bounds
        var viewPortSize = self.bounds.size
        viewPort.size.width *= 3
        viewPort.size.height *= 3
        viewPortSize.width *= 3
        viewPortSize.height *= 3
        let interfaceOrientation : UIInterfaceOrientation
        interfaceOrientation = self.window!.windowScene!.interfaceOrientation
        var image = CIImage(cvImageBuffer: imageBuffer)
        
        // Explanation here: https://stackoverflow.com/questions/58809070/transforming-arframecapturedimage-to-view-size
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)
        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        image = image.transformed(by:normalizeTransform
            .concatenating(displayTransform)
            .concatenating(toViewPortTransform)
        ).cropped(to: viewPort)
        image = image.oriented(.upMirrored)
        
        self.ciContext.render(
            image,
            to: targetTexture,
            commandBuffer: context.commandBuffer,
            bounds: viewPort,
            //colorSpace: CGColorSpaceCreateDeviceRGB()
            //colorSpace: CGColorSpaceCreateDeviceCMYK()
            colorSpace: CGColorSpace(name: CGColorSpace.genericCMYK)! //CGColorSpace(name: CFStringRef(.kCGColorSpaceSRGB))
            //colorSpace: CGColorSpaceCreateDeviceGray()
        )
        
        /*guard let srcColorSpace = CGColorSpace(name: CGColorSpace.genericCMYK),
              let dstColorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else { return }
        let conversionInfo = CGColorConversionInfo(src: srcColorSpace, dst: dstColorSpace)
        let conversion = MPSImageConversion(device: self.device,
                                            srcAlpha: .alphaIsOne,
                                            destAlpha: .alphaIsOne,
                                            backgroundColor: nil,
                                            conversionInfo: conversionInfo)*/
    }
    
    private func combineModelAndBackground(context: ARView.PostProcessContext,
                                           background backgroundTexture: MTLTexture,
                                           model modelTexture: MTLTexture,
                                           noise noiseTexture: MTLTexture,
                                           noiseIntensity: Float,
                                           target targetTexture: MTLTexture
    ) {
        guard let computePipelineState = globalComputePipelineStates["combineModelAndBackground"],
              let encoder = context.commandBuffer.makeComputeCommandEncoder()
        else {
            fatalError("Could not combine model and background")
        }
        
        encoder.setComputePipelineState(computePipelineState)
        encoder.setTexture(backgroundTexture, index: 0)
        encoder.setTexture(modelTexture, index: 1)
        encoder.setTexture(noiseTexture, index: 2)
        encoder.setTexture(targetTexture, index: 3)
        
        var noiseIntensityBytes: [Float] = [noiseIntensity]
        let noiseIntensityBuffer = context.device.makeBuffer(bytes: &noiseIntensityBytes, length: MemoryLayout<Float>.size)
        encoder.setBuffer(noiseIntensityBuffer, offset: 0, index: 0)
        
        let threadsPerThreadgroup = MTLSize(width: computePipelineState.threadExecutionWidth,
                                            height: computePipelineState.maxTotalThreadsPerThreadgroup / computePipelineState.threadExecutionWidth,
                                            depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (context.targetColorTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                           height: (context.targetColorTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                          depth: 1)
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    private func createPostProcess(shaderDescriptors shaders: [ShaderDescriptor]) -> ((ARView.PostProcessContext) -> Void)? {
        var computePipelineStates: [MTLComputePipelineState?] = []
        for shaderDescriptor in shaders {
            loadTextures(shaderDescriptor)
            
            // Metal Performance Shaders generate their own computePipelineState
            if shaderDescriptor.shader.type == .metalPerformanceShader {
                computePipelineStates.append(nil)
                continue
            }
            
            // Load kernel function into the library
            guard let kernelFunction = self.library.makeFunction(name: "\(shaderDescriptor.shader.name)_kernel"),
                  let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
            else {
                return nil
            }
            computePipelineStates.append(computePipelineState)
            print("Loaded kernel function \(shaderDescriptor.shader.name)")
        }
        
        let initialTime = Date().timeIntervalSince1970
        return { context in
            var context = context
            let computePassDescriptor = MTLComputePassDescriptor()
        
            // Background
            self.capturedImageToMTLTexture(context, targetTexture: self.backgroundFrameTexture!)
            guard let frame = self.session.currentFrame else { return }
            // Add model to background
            self.combineModelAndBackground(
                context: context,
                background: self.backgroundFrameTexture,
                model: context.sourceColorTexture,
                noise: frame.cameraGrainTexture!,
                noiseIntensity: frame.cameraGrainIntensity,
                target: self.combinedBackgroundAndModelTexture
            )
            // Used for testing pipeline
            //context.sourceColorTexture = self.globalTextures["calibrationImage"]!
            //context.sourceColorTexture = self.backgroundFrameTexture
            context.sourceColorTexture = self.combinedBackgroundAndModelTexture
            
            // Determine which texture set is to be used
            var sourceTexture: MTLTexture
            var destinationTexture: MTLTexture
            guard let correctionTexture: MTLTexture = self.loadedTextures["correctionTexture"] else {
                assertionFailure()
                return
            }
            let hasCorrectionShaders = self.postProcessCallbacks[.correction] != nil
            let hasSimulationShaders = self.postProcessCallbacks[.simulation] != nil
            if shaders[0].pipelineTarget == .correction {
                sourceTexture = context.sourceColorTexture
                destinationTexture = hasSimulationShaders ? correctionTexture : context.targetColorTexture
            } else {
                sourceTexture = hasCorrectionShaders ? correctionTexture : context.sourceColorTexture
                destinationTexture = context.targetColorTexture
            }
            
            for (i, shaderDescriptor) in shaders.enumerated() {
                if shaderDescriptor.shader.type == .metalPerformanceShader {
                    let mps = shaderDescriptor.shader
                    if mps.mpsFunction != nil {
                        mps.mpsFunction!(context)
                    } else {
                        mps.mpsObject?.process(
                            context: context,
                            sourceTexture: sourceTexture,
                            destinationTexture: destinationTexture
                        )
                    }
                    continue
                }
                
                let computePipelineState = computePipelineStates[i]
                
                guard let encoder = context.commandBuffer.makeComputeCommandEncoder(descriptor: computePassDescriptor) else {
                    continue
                }
                encoder.setComputePipelineState(computePipelineState!)
                encoder.setTexture(sourceTexture, index: 0)
                encoder.setTexture(destinationTexture, index: 1)
                
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
                
                let threadsPerThreadgroup = MTLSize(width: computePipelineState!.threadExecutionWidth,
                                                    height: computePipelineState!.maxTotalThreadsPerThreadgroup / computePipelineState!.threadExecutionWidth,
                                                    depth: 1)
                let threadgroupsPerGrid = MTLSize(width: (context.targetColorTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                                   height: (context.targetColorTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                                  depth: 1)
                encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                encoder.endEncoding()
            }
            
            // commited by postprocess itself
            // context.commandBuffer.commit()
            
            self.currentContext = context
        }
    }
    
    public func runShaders(shaders: [ShaderDescriptor]) {
        if shaders.isEmpty {
            return
        }
        
        let callback = createPostProcess(shaderDescriptors: shaders)
        postProcessCallbacks[shaders[0].pipelineTarget] = callback
        
        renderCallbacks.postProcess = { context in
            var context = context
            let correctionCallback = self.postProcessCallbacks[.correction]
            let simulationCallback = self.postProcessCallbacks[.simulation]
            if correctionCallback != nil {
                correctionCallback!!(context)
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
