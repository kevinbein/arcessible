//
//  daltonization.metal
//  mt-test-1
//
//  Created by Kevin Bein on 04.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"

constexpr sampler s = sampler(coord::normalized, address::clamp_to_edge, filter::linear);

bool isInside(vec2 texel, vec2 dim) {
    if (texel.x < dim.x && texel.y < dim.y) {
        return true;
    } else {
        return false;
    }
}

bool isInlimit(vec2 texel, vec2 dim) {
    if (isInside(texel,dim) && ((texel.x+0.5) == dim.x || (texel.y+0.5) == dim.y)) {
        return true;
    } else {
        return false;
    }
}

// Default kernel method
kernel void daltonizationStep2_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::sample> AtA [[texture(2)]],
    texture2d<float, access::write> temporaryTexture2 [[texture(3)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    //vec4 fragColor = AtA.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    vec2 dimB = vec2(gridPosition);
    vec2 p1 = (vec2(dimB) - 0.5) * 2.0 + 0.5;
    
    vec4 fragColor = AtA.sample(s, p1); // gl_FragColor = texture2DRect( AtA, p1);
    
    vec2 v = vec2(1.0,0.0);
    fragColor = fragColor + ((isInside(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(0.0,1.0);
    fragColor = fragColor + ((isInside(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(1.0,1.0);
    fragColor = fragColor + ((isInside(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    
    v = vec2(0.0,2.0);
    fragColor = fragColor + ((isInlimit(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(1.0,2.0);
    fragColor = fragColor + ((isInlimit(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(2.0,0.0);
    fragColor = fragColor + ((isInlimit(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(2.0,1.0);
    fragColor = fragColor + ((isInlimit(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));
    v = vec2(2.0,2.0);
    fragColor = fragColor + ((isInlimit(p1+v,dimB))?AtA.sample(s, p1 + v):vec4(0.0,0.0,0.0,0.0));

    // ========= Custom code END =========
    
    // Output to screen
    
    temporaryTexture2.write(fragColor, gridPosition);
}
