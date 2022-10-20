//
//  BloomMPS.swift
//  mt-test-1
//
//  Created by Kevin Bein on 26.07.22.
//

import RealityKit
import MetalPerformanceShaders

class BloomMPS: ObjectMPS {
    private var sigma: Float = 9.0
    
    init(sigma: Float) {
        self.sigma = sigma
    }
    
    init() {
    }
    
    public func process(context: ARView.PostProcessContext, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        // let bloom = bloom
        let gaussianBlur = MPSImageGaussianBlur(device: context.device, sigma: sigma)
        gaussianBlur.encode(commandBuffer: context.commandBuffer,
                            sourceTexture: sourceTexture,
                            destinationTexture: destinationTexture
        )
    }
}
