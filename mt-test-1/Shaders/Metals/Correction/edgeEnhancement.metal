//
//  mix.metal
//  mt-test-1
//
//  Created by Kevin Bein on 22.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"

kernel void edgeEnhancement_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    texture2d<float, access::read> edgeTexture [[texture(2)]],
    texture2d<float, access::read> startTexture [[texture(3)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &rate [[buffer(1)]]
) {
    vec4 sourceColor = startTexture.read(gridPosition);
    vec4 edgeColor = edgeTexture.read(gridPosition);
    
    //vec4 fragColor = mix(sourceColor, edgeColor, 0.7);
    vec4 fragColor = max(sourceColor, edgeColor);
    fragColor.r = max(sourceColor.r, edgeColor.r);
    
    targetTexture.write(fragColor, gridPosition);
}
