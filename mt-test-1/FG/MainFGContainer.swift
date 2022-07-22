//
//  MainFGContainer.swift
//  mt-test-1
//
//  Created by Kevin Bein on 17.07.22.
//

import GLKit
import UIKit
import MetalKit
import QuartzCore
import SwiftUI
import ARKit

// https://github.com/FlexMonkey/CoreImageHelpers/blob/master/CoreImageHelpers/coreImageHelpers/ImageView.swift

class FGMetalImageView: MTKView, MTKViewDelegate
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
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, Int(drawableSize.width), Int(drawableSize.height), kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
        
        guard
            let targetTexture = currentDrawable?.texture,
            let imageBuffer = pixelBuffer,
            let drawable = currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor
        else {
            return
        }
        
        let context = CIContext(mtlDevice: device!)
        
        var image = CIImage(cvPixelBuffer: imageBuffer)
        //image = image.applyingFilter("CIGloom")
        //image = image.applyingFilter("CIComicEffect")
            
        //renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0.3)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        //commandEncoder?.setRenderPipelineState(renderPipelineState)
        commandEncoder?.endEncoding()
        
        let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
        context.render(image,
                         to: targetTexture,
                         commandBuffer: commandBuffer,
                         bounds: bounds,
                         colorSpace: colorSpace)
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
        //super.draw()
    }
}

struct MainFGContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> FGMetalImageView {
        return FGMetalImageView()
    }
    
    func updateUIView(_ mtkView: FGMetalImageView, context: Context) {
    }
}
