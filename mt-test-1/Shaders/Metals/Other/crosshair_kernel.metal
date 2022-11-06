//
//  crosshair_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 05.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"

constant vec4 backgroundColor = vec4(0.18,0.18,0.18,1);
constant vec4 crosshairsColor = vec4(1,1,1,1);
constant vec2 centerUV = vec2(0.5, 0.5);
constant float thickness = 5.;
constant float crosshairLength = 70.;

// Boolean like functions as described here:
// http://theorangeduck.com/page/avoiding-shader-conditionals

// return 1 if x > y, 0 otherwise.
float gt(float x, float y)
{
    return max(sign(x-y), 0.0);
}

// x and y must be either 0 or 1.
float and_(float x, float y)
{
    return x * y;
}

// x and y must be 0 or 1.
float or_(float x, float y)
{
    return min(x + y, 1.0);
}

// x must be 0 or 1
float not_(float x)
{
    return 1.0 - x;
}


kernel void crosshair_kernel(
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
    
    // Normalized pixel coordinates (from 0 to 1)
    ////vec2 center = iResolution.xy * centerUV;
    //vec2 center = (fragCoord - .5 / iResolution.xy) / iResolution.y;
    //vec2 d = abs(center - fragCoord);
    //float crosshairMask = or_(and_(gt(thickness, d.x), gt(crosshairLength, d.y)),
    //                         and_(gt(thickness, d.y), gt(crosshairLength, d.x)));
    //float backgroundMask = not_(crosshairMask);
    //vec4 col = crosshairMask * crosshairsColor + backgroundMask * backgroundColor;
    
    
    // Normalized pixel coordinates (from 0 to 1)
        vec2 center = iResolution.xy * centerUV;
        vec2 d = abs(center - fragCoord);
        
        float crosshairMask = or_(and_(gt(thickness, d.x), gt(crosshairLength, d.y)),
                                 and_(gt(thickness, d.y), gt(crosshairLength, d.x)));
        
        float backgroundMask = not_(crosshairMask);
        
        vec4 col = crosshairMask * crosshairsColor + backgroundMask * fragColor;

    
    // ========= Custom code END =========
    
    
    // Place upon image
    //col = min(fragColor, col);
    
    // Output to screen
    fragColor = col;
    
    targetTexture.write(fragColor, gridPosition);
}
