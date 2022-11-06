//
//  bgwbd.metal
//  mt-test-1
//
//  Created by Kevin Bein on 06.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

// Background White Black Depth kernel
kernel void bgwbd_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    texture2d<float, access::read> depthTexture [[texture(2)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &coloringType [[buffer(1)]]
) {
    vec4 sourceColor = sourceTexture.read(gridPosition);
    
    // Depth
    float depthValue = depthTexture.read(gridPosition).r;
    
    // Color
    const float hue = 0.0;
    const float saturation = 0.5;
    const float brightness = 0.5;
    const float contrast = depthValue / 10.0;
    vec4 rgba = sourceColor;
    rgba = gammaCorrection(sourceColor.rgb);
    float4 hsbc = vec4(hue, saturation, brightness, contrast);
    vec4 outputColor = applyHSBCffect(rgba, hsbc);
    
    targetTexture.write(outputColor, gridPosition);
}
