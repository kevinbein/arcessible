//
//  floaters.metal
//  mt-test-1
//
//  Created by Kevin Bein on 17.07.22.
//

#include <metal_stdlib>
using namespace metal;

float2 rand(float2 co) {
    return float2(
        fract(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453),
        fract(cos(dot(co.yx, float2(8.64947,45.097))) * 43758.5453)
    ) * 2.0 - 1.0;
}

float dots(float2 uv, float iTime)
{
    // Consider the integer component of the UV coordinate
    // to be an ID of a local coordinate space.
    float2 g = floor(uv) + (iTime*.0000001);
    // "What 'local coordinate space'?" you say? Why the one
    // implicitly defined by the fractional component of
    // the UV coordinate. Here we translate the origin to the
    // center.
    float2 f = fract(uv) * 2.0 - 1.0;
    
    // Get a random value based on the "ID" of the coordinate
    // system. This value is invariant across the entire region.
    float2 r = rand(g) * 0.5;
    
    // Return the distance to that point.
    return length(f + r);
}

kernel void floatersDots_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &iTime [[buffer(0)]]
) {
    float4 sourceColor = sourceTexture.read(gridPosition);
    
    float2 resolution = float2(sourceTexture.get_width(), sourceTexture.get_height());
    
    float2 uv = float2(gridPosition) / resolution - 0.5;
    uv.x *= resolution.x / resolution.y; //fix aspect ratio
    
    float d = smoothstep(0.1, 0.7, dots(uv * 7.0, iTime));
    //float4 outColor = float4(postProcess(uv, float3(1.0, d, d)), 1.0);
    float4 outColor = min(sourceColor, float4(d, d, d, 1.0));
    
    // Visualize grid
    //float4 outColor = float4(uv, 0.0, 1.0);
    
    targetTexture.write(outColor, gridPosition);
}

