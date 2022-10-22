//
//  capturedImageColorspaceConverter_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 20.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"

kernel void capturedImageColorspaceConverter_kernel(
    texture2d<float, access::sample> capturedImageTextureY [[texture(0)]],
    texture2d<float, access::sample> capturedImageTextureCbCr [[texture(1)]],
    texture2d<float, access::write> targetTexture [[texture(2)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    
    vec2 textCoord = vec2(gridPosition);

    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    vec4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, textCoord).r,
                        capturedImageTextureCbCr.sample(colorSampler, textCoord).rg, 1.0);

    targetTexture.write(ycbcrToRGBTransform * ycbcr, gridPosition);
}
