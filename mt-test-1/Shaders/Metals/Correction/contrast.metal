//
//  contrast.metal
//  mt-test-1
//
//  Created by Kevin Bein on 17.10.22.
//

#include <metal_stdlib>
using namespace metal;

kernel void inverseColor_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]]
) {
    float4 sourceColor = sourceTexture.read(gridPosition);
    float4 inverseColor = float4(1.0 - sourceColor.rgb, sourceColor.a);

    targetTexture.write(inverseColor, gridPosition);
}
