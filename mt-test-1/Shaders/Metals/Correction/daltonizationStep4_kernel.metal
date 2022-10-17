//
//  daltonization.metal
//  mt-test-1
//
//  Created by Kevin Bein on 04.10.22.
//

#include <metal_stdlib>
using namespace metal;

// Metal Shadertoy types
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat3 float3x3

constexpr sampler s = sampler(coord::normalized, address::clamp_to_edge, filter::linear);

bool isInside2(vec2 texel, vec2 dim) {
    if (texel.x < dim.x && texel.y < dim.y) {
        return true;
    } else {
        return false;
    }
}

bool isInlimit2(vec2 texel, vec2 dim) {
    if (isInside2(texel,dim) && ((texel.x+0.5) == dim.x || (texel.y+0.5) == dim.y)) {
        return true;
    } else {
        return false;
    }
}

// Default kernel method
kernel void daltonizationStep4_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::sample> ProjEffect [[texture(2)]],
    texture2d<float, access::write> temporaryTexture4 [[texture(3)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    //vec4 fragColor = AtA.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    vec2 dimB = vec2(gridPosition);
    vec2 p1 = (vec2(dimB) - 0.5) * 2.0 + 0.5;
    
    vec4 fragColor;
    fragColor.xy = abs(ProjEffect.sample(s, p1).xy);
    
    vec2 v = vec2(1.0,0.0);
    fragColor.xy = max(fragColor.xy,((isInside2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(0.0,1.0);
    fragColor.xy = max(fragColor.xy,((isInside2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(1.0,1.0);
    fragColor.xy = max(fragColor.xy,((isInside2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    
    v = vec2(0.0,2.0);
    fragColor.xy = max(fragColor.xy,((isInlimit2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(1.0,2.0);
    fragColor.xy = max(fragColor.xy,((isInlimit2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(2.0,0.0);
    fragColor.xy = max(fragColor.xy,((isInlimit2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(2.0,1.0);
    fragColor.xy = max(fragColor.xy,((isInlimit2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    v = vec2(2.0,2.0);
    fragColor.xy = max(fragColor.xy,((isInlimit2(p1+v,dimB))?abs(ProjEffect.sample(s, p1 + v).xy):vec2(0.0,0.0)));
    
    //col = fragColor;
    
    // ========= Custom code END =========
    
    // Output to screen
    //fragColor = vec4(vec3(col), 1.0);
    
    temporaryTexture4.write(fragColor, gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
