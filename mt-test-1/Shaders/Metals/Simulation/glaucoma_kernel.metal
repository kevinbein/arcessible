//
//  glaucoma_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 15.08.22.
//

#include <metal_stdlib>
using namespace metal;

// Central view only, outer edges are black with a fade in effect
// See: https://www.eyesiteonwellness.com/eye-diseases/

#include "../Utils/types.h"

// Default kernel method
kernel void glaucoma_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    // Metal to Shadertoy naming conversion
    vec4 fragColor = sourceTexture.read(gridPosition);
    vec2 fragCoord = float2(gridPosition);
    vec2 iResolution = float2(sourceTexture.get_width(), sourceTexture.get_height());
    
    // Default Shadertoy setup
    // No coordinate aligning
    vec2 uv = fragCoord / iResolution.xy;
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = (fragCoord - .5 / iResolution.xy) / iResolution.y;

    // Shadertoy "Background image"
    //vec4 backgroundColor = float4(uv.xy, 0.0 ,1.0);
 
    
    // ========= Custom code START =========
    
    float d = .5 - length(uv - .5);
    vec4 col = vec4(vec3(d), 1.0);

    // ========= Custom code END =========
    
    
    // Place upon image
    col = min(fragColor, col);
    
    // Output to screen
    fragColor = col;
    
    targetTexture.write(fragColor, gridPosition);
}
