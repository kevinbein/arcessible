//
//  GaussianBlur.swift
//  mt-test-1
//
//  Created by Kevin Bein on 16.07.22.
//

import RealityKit
import MetalPerformanceShaders

/*func mpsGaussianBlur(context: ARView.PostProcessContext) {
    let gaussianBlur = MPSImageGaussianBlur(device: context.device, sigma: 4)
    gaussianBlur.encode(commandBuffer: context.commandBuffer,
                        sourceTexture: context.sourceColorTexture,
                        destinationTexture: context.targetColorTexture
    )
}*/

class GaussianBlurMPS: ObjectMPS {
    private var sigma: Float = 9.0
    
    init(sigma: Float) {
        self.sigma = sigma
    }
    
    init() {
    }
    
    public func process(context: ARView.PostProcessContext, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        let gaussianBlur = MPSImageGaussianBlur(device: context.device, sigma: sigma)
        gaussianBlur.encode(commandBuffer: context.commandBuffer,
                            sourceTexture: sourceTexture,
                            destinationTexture: destinationTexture
        )
    }
}
