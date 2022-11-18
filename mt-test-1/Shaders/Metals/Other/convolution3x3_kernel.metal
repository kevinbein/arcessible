//
//  contrastCheck_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 18.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

kernel void convolution3x3_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    constexpr sampler s = sampler(coord::pixel, address::clamp_to_edge, filter::linear);
    //constexpr sampler s(coord::pixel, mag_filter::linear, min_filter::linear);
    
    
    // float4 sourceColor = sourceTexture.read(gridPosition);
    float2 resolution = float2(sourceTexture.get_width(), sourceTexture.get_height());
    float2 uv = float2(gridPosition) / resolution;
    uv.x *= resolution.x / resolution.y;
    
    vec3 averageColor = vec3(0.0, 0.0, 0.0);
    if (gridPosition.x > 0 && gridPosition.y > 0 && gridPosition.x < resolution.x-1 && gridPosition.y < resolution.y-1) {
        vec3 averageColorAdded = vec3(0.0);
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x - 1, gridPosition.y - 1)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x - 1, gridPosition.y + 0)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x - 1, gridPosition.y + 1)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 0, gridPosition.y - 1)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 0, gridPosition.y + 0)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 0, gridPosition.y + 1)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 1, gridPosition.y - 1)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 1, gridPosition.y + 0)));
        averageColorAdded += vec3(sourceTexture.sample(s, vec2(gridPosition.x + 1, gridPosition.y + 1)));
        averageColor = averageColorAdded / 9.0;
        
        //averageColor = vec3(sourceTexture.sample(s, vec2(gridPosition.x, gridPosition.y)));
    } else { // edges
        // ignore for now
        //vec3 averageColor = vec3(1.0, 0.0, 1.0);
    }
    targetTexture.write(vec4(averageColor, 1.0), gridPosition);
}
