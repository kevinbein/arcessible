//
//  depth_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 05.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

kernel void depth_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    texture2d<float, access::read> depthTexture [[texture(2)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &coloringType [[buffer(1)]]
) {
    //constexpr sampler colorSampler(address::clamp_to_edge, filter::nearest);
    
    //vec4 col = depthTexture.sample(colorSampler, vec2(gridPosition));
    //float depthValue = depthTexture.read(uint2(gridPosition.x / 4, gridPosition.y / 4)).r;
    /*//float normalizedDepthValue = depthValue / 5.0;
    //vec4 col = vec4(vec3(normalizedDepthValue), 1.0);
    vec4 col = vec4(vec3(normalizedDepthValue), 1.0);
    col = mix(sourceTexture.read(gridPosition), col, 0.5);
     */
    
    float depthValue = depthTexture.read(gridPosition).r;
    // Size the color gradient to a maximum distance of 2.5 meters.
    // The LiDAR Scanner supports a value no larger than 5.0; the
    // sample app uses a value of 2.5 to better distinguish depth
    // in smaller environments.
    //half val = s.r / 2.5h;
    
    vec4 col;
    if (coloringType == 1.0) { // Jet color scheme
        float val = depthValue;
        col = getJetColorsFromNormalizedVal(val);
    } else { // Black/White color scheme
        col = vec4(vec3(1.0 - (depthValue / 2.0)), 1.0);
    }
    
    targetTexture.write(col, gridPosition);
}
