//
//  MainBGView.swift
//  mt-test-1
//
//  Created by Kevin Bein on 05.05.22.
//

import GLKit
import UIKit
import MetalKit
import QuartzCore
import SwiftUI
import ARKit

// https://github.com/FlexMonkey/CoreImageHelpers/blob/master/CoreImageHelpers/coreImageHelpers/ImageView.swift

class MetalImageView: MTKView, MTKViewDelegate
{
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    var textureCache: CVMetalTextureCache!
    var ciContext: CIContext?
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        guard let device = device ?? MTLCreateSystemDefaultDevice() else {
            fatalError("Could not find device")
        }
        super.init(frame: frameRect, device: device)
        if super.device == nil {
            fatalError("Device doesn't support Metal")
        }
        
        delegate = self
        
        preferredFramesPerSecond = 60
        enableSetNeedsDisplay = true
        
        framebufferOnly = false
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        drawableSize = frameRect.size
        enableSetNeedsDisplay = true
        
        commandQueue = device.makeCommandQueue()
        
        // Create Pipeline State is more complex, because we need to pass in the shader functions and update the render pipeline descriptor and state.
        
//        // The device will make a library for us
//        //let library = device.makeDefaultLibrary()
//        // Our vertex function name
//        //let vertexFunction = library?.makeFunction(name: "basic_vertex_function")
//        // Our fragment function name
//        //let fragmentFunction = library?.makeFunction(name: "basic_fragment_function")
//        // Create basic descriptor
//        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
//        // Attach the pixel format that is the same as the MetalView
//        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//        // Attach the shader functions
//        //renderPipelineDescriptor.vertexFunction = vertexFunction
//        //renderPipelineDescriptor.fragmentFunction = fragmentFunction
//        // Try to update the state of the renderPipeline
//        do {
//            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
//        } catch {
//            print(error.localizedDescription)
//        }
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        
        // Other
        framebufferOnly = false
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
        var mtlTexture: MTLTexture? = nil
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        if status == kCVReturnSuccess {
            mtlTexture = CVMetalTextureGetTexture(texture!)
        }
        
        return mtlTexture
    }
    
    /// The image to display
    var arFrame: ARFrame? {
        didSet {
            self.setNeedsDisplay()
            //renderImage()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard
            let targetTexture = currentDrawable?.texture,
            let imageBuffer = arFrame?.capturedImage,
            let drawable = currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor
        else {
            return
        }
        
        let context = CIContext(mtlDevice: device!)
        
        var image = CIImage(cvPixelBuffer: imageBuffer)
        //image = image.applyingFilter("CIGloom")
        //image = image.applyingFilter("CIComicEffect")
        
        let maxScale = max(drawableSize.height / image.extent.width, drawableSize.width / image.extent.height)
        let transformationMatrix = CGAffineTransform.identity
            .translatedBy(x: -334, y: 0)
            .scaledBy(x: maxScale, y: maxScale)
            .rotated(by: -90 * .pi / 180)
            .translatedBy(x: -1920, y: 0)
        let scaledImage = image
            .transformed(by: transformationMatrix)
        /// Same as
        //  .transformed(by: CGAffineTransform(a: 0, b: -1.31875, c: 1.31875, d: 0, tx: -334.0, ty: 2532.0))
        /// Same as
        //  .transformed(by: CGAffineTransform(translationX: -1920, y: 0))
        //  .transformed(by: CGAffineTransform(rotationAngle: -90 * .pi / 180 ))
        //  .transformed(by: CGAffineTransform(scaleX: maxScale, y: maxScale))
        //  .transformed(by: CGAffineTransform(translationX: -334, y: 0))
            
        //renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0.3)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        //commandEncoder?.setRenderPipelineState(renderPipelineState)
        commandEncoder?.endEncoding()
        
        let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
        context.render(scaledImage,
                         to: targetTexture,
                         commandBuffer: commandBuffer,
                         bounds: bounds,
                         colorSpace: colorSpace)
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
        //super.draw()
    }
}

struct MainBGContainer: UIViewRepresentable {
    var arFrame: ARFrame?
    //    @Binding var image: CIImage?
    
    init(arFrame: ARFrame?) {
        self.arFrame = arFrame
    }
    
    func makeUIView(context: Context) -> MetalImageView {
        return MetalImageView()
    }
    
    func updateUIView(_ mtkView: MetalImageView, context: Context) {
        mtkView.arFrame = self.arFrame
    }
}
