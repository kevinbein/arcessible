//
//  Canny.swift
//  mt-test-1
//
//  Created by Kevin Bein on 22.10.22.
//

import RealityKit
import MetalPerformanceShaders

class CannyMPS: ObjectMPS {
    //private var sigma: Float = 1.0
    
    init(sigma: Float) {
        //self.sigma = sigma
    }
    
    init() {
    }
    
    public func process(context: ARView.PostProcessContext, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        let canny = MPSImageCanny(device: context.device)
        canny.encode(commandBuffer: context.commandBuffer,
                     sourceTexture: sourceTexture,
                     destinationTexture: destinationTexture
        )
    }
}
