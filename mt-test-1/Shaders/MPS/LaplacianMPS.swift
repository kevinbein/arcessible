//
//  LaplacianMPS.swift
//  mt-test-1
//
//  Created by Kevin Bein on 22.10.22.
//

import RealityKit
import MetalPerformanceShaders

class LaplacianMPS: ObjectMPS {
    private var bias: Float = 1.0
    private var scale: Float = 1.0
    
    init(bias: Float, scale: Float) {
        self.bias = bias
        self.scale = scale
    }
    
    init() {
    }
    
    public func process(context: ARView.PostProcessContext, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        let laplacian = MPSImageLaplacian(device: context.device)
        laplacian.encode(commandBuffer: context.commandBuffer,
                            sourceTexture: sourceTexture,
                            destinationTexture: destinationTexture
        )
    }
}
