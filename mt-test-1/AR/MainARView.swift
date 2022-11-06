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
    enum FrameMode {
        case separate, combined
        var id: Self { self }
    }
    enum FrameTarget {
        case combined, background, model
        var id: Self { self }
    }
    public struct ShaderChain {
        var shaders: [ShaderDescriptor]
        var pipelineTarget: PipelineTarget
        var frameMode: FrameMode = .combined
    }
    public struct ShaderDescriptor {
        var shader: Shader
        var frameTarget: FrameTarget = .combined
        var arguments: [Float]
        var textures: [String]
        var targetTexture: String? = nil
    }
    
    private var device: MTLDevice!
    private var ciContext: CIContext!
    private var textureCache: CVMetalTextureCache!
    // private var metalLayer: CAMetalLayer!
    private var renderPipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue!
    private var library: MTLLibrary!
    private var globalComputePipelineStates: [String:MTLComputePipelineState] = [:]
    //private var computePipelineState: MTLComputePipelineDescriptor!
    private var loadedTextures: [String:MTLTexture] = [:]
    private var postProcessCallbacks: [PipelineTarget:((ARView.PostProcessContext) -> Void)?] = [:]
    
    private var testTexture: MTLTexture!
    private var targetTestTexture: MTLTexture!
    
    private var rawFrame: ARFrame?
    private var depthImage: ARDepthData?
    private var depthSmoothImage: ARDepthData?
    //private var backgroundTexture: MTLTexture!
    //private var modelTexture: MTLTexture!
    //private var combinedBackgroundAndModelTexture: MTLTexture!
    
    public var currentContext: PostProcessContext?
    
    
    required init() {
        super.init(frame: .zero)
        
        setupCoachingOverlay() // not really activating when used with lidar phone
        setupConfiguration()
        setupRenderingProcess()
        
        generateEvaluationScene()
    }
    
    public func updateFrameData(frame: ARFrame) {
        self.depthImage = frame.sceneDepth
        self.depthSmoothImage = frame.smoothedSceneDepth
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
            
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &self.textureCache)
            
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
        configuration.frameSemantics = [ .sceneDepth, .smoothedSceneDepth ]
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
    
    private func getColorTextureDescriptor() -> MTLTextureDescriptor{
        let textureDescriptor = MTLTextureDescriptor()
        // .rgba32Float works for depth data, .depth32Float does not ... the .bgra10_xr_srgb works for both
        textureDescriptor.pixelFormat = .bgra10_xr_srgb //MTLPixelFormatBGRA10_XR_sRGB
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
            loadedTextures[name] = texture
            print("Loaded global texture \(fullName)")
        }
        
        // Intermediate textures
        let genericTextureDescriptor = getColorTextureDescriptor()
        let textureNames = [
            "g_startBackgroundTexture", "g_startModelTexture", "g_startCombinedBackgroundAndModelTexture",
            "g_backgroundTexture", "g_modelTexture", "g_combinedBackgroundAndModelTexture",
            "g_targetBackgroundTexture", "g_targetModelTexture", "g_targetCombinedBackgroundAndModelTexture",
            "g_depthTexture"
        ]
        for name in textureNames {
            if self.loadedTextures[name] == nil {
                self.loadedTextures[name] = device.makeTexture(descriptor: genericTextureDescriptor)
                print("Loaded texture \(name)")
            }
        }

        //guard let combinedBackgroundAndModelTexture = device.makeTexture(descriptor: genericTextureDescriptor) else { fatalError() }
        //self.combinedBackgroundAndModelTexture = combinedBackgroundAndModelTexture
        //guard let targetCombinedBackgroundAndModelTexture = device.makeTexture(descriptor: genericTextureDescriptor) else { fatalError() }
        //self.targetCombinedBackgroundAndModelTexture = targetCombinedBackgroundAndModelTexture
    }
    
    private func loadTextures(_ shaderDescriptor: ShaderDescriptor) {
        // Special textures
        if shaderDescriptor.targetTexture != nil {
            let textureDescriptor = getColorTextureDescriptor()
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else { return }
            loadedTextures[shaderDescriptor.targetTexture!] = texture
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
                let textureDescriptor = getColorTextureDescriptor()
                guard let texture = device.makeTexture(descriptor: textureDescriptor) else { continue }
                loadedTextures[name] = texture
                
            case "noise":
                let textureDescriptor = getColorTextureDescriptor()
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
    
    private func pixelBufferToMTLTexture(_ context: ARView.PostProcessContext, input: CVPixelBuffer, targetTexture: MTLTexture) {
        guard let frame = self.session.currentFrame else { return }
        let imageBuffer = input
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let imageSize = CGSize(width: width, height: height)
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
        //image = image.oriented(.down)
        
        //var cvtexture: CVMetalTexture?
        //_ = CVMetalTextureCacheCreateTextureFromImage(nil, self.textureCache, image.pixelBuffer!, nil, targetTexture.pixelFormat, width, height, 0, &cvtexture)
        //targetTexture = CVMetalTextureGetTexture(cvtexture!)!
        
        self.ciContext.render(
            image,
            to: targetTexture,
            commandBuffer: context.commandBuffer,
            bounds: viewPort,
            colorSpace: CGColorSpaceCreateDeviceRGB()
            //colorSpace: CGColorSpaceCreateDeviceCMYK()
            //colorSpace: CGColorSpace(name: CGColorSpace.genericCMYK)! //CGColorSpace(name: CFStringRef(.kCGColorSpaceSRGB))
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
                                           //noise noiseTexture: MTLTexture,
                                           //noiseIntensity: Float,
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
        //encoder.setTexture(noiseTexture, index: 2)
        encoder.setTexture(context.targetColorTexture, index: 2)
        
        //var noiseIntensityBytes: [Float] = [noiseIntensity]
        //let noiseIntensityBuffer = context.device.makeBuffer(bytes: &noiseIntensityBytes, length: MemoryLayout<Float>.size)
        //encoder.setBuffer(noiseIntensityBuffer, offset: 0, index: 0)
        
        let threadsPerThreadgroup = MTLSize(width: computePipelineState.threadExecutionWidth,
                                            height: computePipelineState.maxTotalThreadsPerThreadgroup / computePipelineState.threadExecutionWidth,
                                            depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (context.targetColorTexture.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                           height: (context.targetColorTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                          depth: 1)
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    //private func createPostProcess(shaderDescriptors shaders: [ShaderDescriptor], pipelineTarget: PipelineTarget) -> ((ARView.PostProcessContext) -> Void)? {
    private func createPostProcess(chain: ShaderChain) -> ((ARView.PostProcessContext) -> Void)? {
        var computePipelineStates: [MTLComputePipelineState?] = []
        for shaderDescriptor in chain.shaders {
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
        
            // Add model to background
            /*self.combineModelAndBackground(
                context: context,
                background: loadedTextures["backgroundTexture"],
                model: loadedTextures["modelTexture"],
                noise: self.rawFrame.cameraGrainTexture!,
                noiseIntensity: frame.cameraGrainIntensity,
                target: loadedTextures["combinedBackgroundAndModelTexture"]
            )*/
            // Used for testing pipeline
            //context.sourceColorTexture = self.globalTextures["calibrationImage"]!
            //context.sourceColorTexture = self.backgroundFrameTexture
            //context.sourceColorTexture = self.combinedBackgroundAndModelTexture
            
            // Determine which texture set is to be used
            var sourceTexture: MTLTexture!
            var destinationTexture: MTLTexture!
            
            for (i, shaderDescriptor) in chain.shaders.enumerated() {
                
                if chain.frameMode == .combined {
                    sourceTexture = self.loadedTextures["g_combinedBackgroundAndModelTexture"]!
                    destinationTexture = context.targetColorTexture
                } else {
                    if shaderDescriptor.frameTarget == .background {
                        sourceTexture = self.loadedTextures["g_backgroundTexture"]!
                        destinationTexture = self.loadedTextures["g_targetBackgroundTexture"]!
                    } else {
                        sourceTexture = self.loadedTextures["g_modelTexture"]!
                        //destinationTexture = context.targetColorTexture
                        destinationTexture = self.loadedTextures["g_targetModelTexture"]!
                    }
                }
                
                if shaderDescriptor.shader.type == .metalPerformanceShader {
                    let mps = shaderDescriptor.shader
                    if mps.mpsFunction != nil {
                        mps.mpsFunction!(context)
                    } else {
                        mps.mpsObject?.process(
                            context: context,
                            sourceTexture: sourceTexture,
                            destinationTexture: context.targetColorTexture
                        )
                    }
                    
                    guard let blitEncoder = context.commandBuffer.makeBlitCommandEncoder() else { continue }
                    blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures["g_backgroundTexture"]!)
                    blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures["g_modelTexture"]!)
                    blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures["g_combinedBackgroundAndModelTexture"]!)
                    blitEncoder.endEncoding()
                    
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
                // context.targetColorTexture must be set before endEncoding(). Otherwise nothing will be drawn...
                encoder.endEncoding()
                
                if chain.frameMode == .separate {
                    let backgroundTexture: MTLTexture!
                    let modelTexture: MTLTexture!
                    if shaderDescriptor.frameTarget == .background {
                        backgroundTexture = self.loadedTextures["g_targetBackgroundTexture"]!
                        modelTexture = self.loadedTextures["g_modelTexture"]!
                    } else {
                        backgroundTexture = self.loadedTextures["g_backgroundTexture"]!
                        modelTexture = self.loadedTextures["g_targetModelTexture"]!
                    }
                    
                    self.combineModelAndBackground(
                        context: context,
                        background: backgroundTexture,
                        model: modelTexture,
                        //noise: frame.cameraGrainTexture!,
                        //noiseIntensity: frame.cameraGrainIntensity,
                        target: context.targetColorTexture
                    )
                    
                    guard let blitEncoder = context.commandBuffer.makeBlitCommandEncoder() else { continue }
                    blitEncoder.copy(from: backgroundTexture, to: self.loadedTextures["g_backgroundTexture"]!)
                    blitEncoder.copy(from: modelTexture, to: self.loadedTextures["g_modelTexture"]!)
                    blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures["g_combinedBackgroundAndModelTexture"]!)
                    if shaderDescriptor.targetTexture != nil {
                        blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures[shaderDescriptor.targetTexture!]!)
                    }
                    blitEncoder.endEncoding()
                } else {
                    guard let blitEncoder = context.commandBuffer.makeBlitCommandEncoder() else { continue }
                    blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures["g_combinedBackgroundAndModelTexture"]!)
                    if shaderDescriptor.targetTexture != nil {
                        blitEncoder.copy(from: context.targetColorTexture, to: self.loadedTextures[shaderDescriptor.targetTexture!]!)
                    }
                    blitEncoder.endEncoding()
                }
            }
            
            // commited by postprocess itself
            // context.commandBuffer.commit()
            
            self.currentContext = context
        }
    }
    
    private func setEnvironmentBackground(transparent: Bool = false) {
        if transparent {
            environment.background = Environment.Background.color(.black.withAlphaComponent(0.0))
        } else {
            environment.background = Environment.Background.cameraFeed()
        }
    }
    
    public func runShaders(chain: ShaderChain) {
        if chain.shaders.isEmpty {
            return
        }
        
        setEnvironmentBackground(transparent: chain.frameMode == .separate)
        // Reset global textures
        loadGlobalTextures()
        
        let callback = createPostProcess(chain: chain)
        postProcessCallbacks[chain.pipelineTarget] = callback
        
        if renderCallbacks.postProcess != nil {
            return
        }
        
        renderCallbacks.postProcess = { context in
            var context = context
            
            guard let frame = self.session.currentFrame else { return }
            //let h = context.targetColorTexture.height
            //let w = context.targetColorTexture.width
            //frame.displayTransform(for: .portrait, viewportSize: CGSizeMake(CGFloat(w), CGFloat(h)))
            self.pixelBufferToMTLTexture(context, input: frame.capturedImage, targetTexture: self.loadedTextures["g_backgroundTexture"]!)
            if frame.smoothedSceneDepth != nil {
                self.pixelBufferToMTLTexture(context, input: frame.smoothedSceneDepth!.depthMap, targetTexture: self.loadedTextures["g_depthTexture"]!)
            }
            
            guard let blitEncoder = context.commandBuffer.makeBlitCommandEncoder() else { return }
            blitEncoder.copy(from: self.loadedTextures["g_backgroundTexture"]!, to: self.loadedTextures["g_startBackgroundTexture"]!)
            blitEncoder.copy(from: context.sourceColorTexture, to: self.loadedTextures["g_startModelTexture"]!)
            blitEncoder.copy(from: context.sourceColorTexture, to: self.loadedTextures["g_startCombinedBackgroundAndModelTexture"]!)
            blitEncoder.copy(from: context.sourceColorTexture, to: self.loadedTextures["g_modelTexture"]!)
            blitEncoder.copy(from: context.sourceColorTexture, to: self.loadedTextures["g_combinedBackgroundAndModelTexture"]!)
            blitEncoder.endEncoding()
            
            /*if chain.frameMode == .separate {
                // captured image
                self.capturedImageToMTLTexture(context, targetTexture: self.loadedTextures["g_backgroundTexture"]!)
                // model only (transparent background)
                self.loadedTextures["g_modelTexture"] = context.sourceColorTexture
            } else {
                self.loadedTextures["g_combinedBackgroundAndModelTexture"] = context.sourceColorTexture
            }*/
            
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
            setEnvironmentBackground(transparent: false)
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
 
    struct GeneratedSceneEntityDescriptor {
        let name: String?
        let position: SIMD3<Float>?
        let material: SimpleMaterial?
    }
    
    func generateEvaluationScene() {
        /*let colors: [UIColor] = [.red, .blue, .green ]
        for i in 0..<10 {
            let material = SimpleMaterial(color: colors.randomElement(), isMetallic: false)
            let descriptor: GeneratedSceneEntityDescriptor(
                name: "Generated Cube \(i)",
                position: [0.0, 0.0, 1.0],
                material: material
            )
            descriptor.name = "Generated Cube \(i)"
        }*/
        
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
            scene.addAnchor(ar)
        }
    }
}
