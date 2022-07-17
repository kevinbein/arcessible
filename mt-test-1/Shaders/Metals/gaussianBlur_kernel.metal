//
//  gaussianBlur_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 16.07.22.
//

#include <metal_stdlib>
using namespace metal;

kernel void gaussianBlur_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    float4 sourceColor = sourceTexture.read(gridPosition);
    float4 inverseColor = float4(1.0 - sourceColor.rgb, sourceColor.a);
    float2 offset = float2(gridPosition);
    
    constexpr sampler qsampler(coord::normalized, address::clamp_to_edge);
    
    float width = sourceTexture.get_width();
    float height = sourceTexture.get_width();
    float xPixel = (1 / width) * 3;
    float yPixel = (1 / height) * 2;
    
    
    float3 sum = float3(0.0, 0.0, 0.0);
    
    
    // code from https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson5
    
    // 9 tap filter
    sum += sourceTexture.sample(qsampler, float2(offset.x - 4.0*xPixel, offset.y - 4.0*yPixel)).rgb * 0.0162162162;
    sum += sourceTexture.sample(qsampler, float2(offset.x - 3.0*xPixel, offset.y - 3.0*yPixel)).rgb * 0.0540540541;
    sum += sourceTexture.sample(qsampler, float2(offset.x - 2.0*xPixel, offset.y - 2.0*yPixel)).rgb * 0.1216216216;
    sum += sourceTexture.sample(qsampler, float2(offset.x - 1.0*xPixel, offset.y - 1.0*yPixel)).rgb * 0.1945945946;
    
    sum += sourceTexture.sample(qsampler, offset).rgb * 0.2270270270;
    
    sum += sourceTexture.sample(qsampler, float2(offset.x + 1.0*xPixel, offset.y + 1.0*yPixel)).rgb * 0.1945945946;
    sum += sourceTexture.sample(qsampler, float2(offset.x + 2.0*xPixel, offset.y + 2.0*yPixel)).rgb * 0.1216216216;
    sum += sourceTexture.sample(qsampler, float2(offset.x + 3.0*xPixel, offset.y + 3.0*yPixel)).rgb * 0.0540540541;
    sum += sourceTexture.sample(qsampler, float2(offset.x + 4.0*xPixel, offset.y + 4.0*yPixel)).rgb * 0.0162162162;
    
    float4 adjusted;
    adjusted.rgb = sum;
//    adjusted.g = color.g;
    adjusted.a = 1;
    
    targetTexture.write(adjusted, gridPosition);
}
