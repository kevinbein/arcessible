//
//  SobelMPS.swift
//  mt-test-1
//
//  Created by Kevin Bein on 04.10.22.
//

import RealityKit
import MetalPerformanceShaders

class SobelMPS: ObjectMPS {
    private var sigma: Float = 9.0
    
    init(sigma: Float) {
        self.sigma = sigma
    }
    
    init() {
    }
    
    public func process(context: ARView.PostProcessContext) {
        let sobel = MPSImageSobel(device: context.device)
        sobel.encode(commandBuffer: context.commandBuffer,
                            sourceTexture: context.sourceColorTexture,
                            destinationTexture: context.targetColorTexture
        )
    }
}
