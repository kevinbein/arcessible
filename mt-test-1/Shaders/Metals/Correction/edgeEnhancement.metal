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
    // color: 0.0 = white, 1.0 = black, 2.0 = red, 3.0 = green, 4.0 = blue
    constant float &color [[buffer(1)]]
) {
    vec4 sourceColor = startTexture.read(gridPosition);
    vec4 edgeColor = edgeTexture.read(gridPosition);
    
    vec4 fragColor;
    
    if (color == 0.0) {
        // white
        fragColor = max(sourceColor, - edgeColor);
        fragColor.r = max(sourceColor.r, edgeColor.r);
    }
    else if (color == 1.0) {
        // black
        fragColor = min(sourceColor, 1.0 - edgeColor);
        fragColor.r = min(sourceColor.r, edgeColor.r);
    }
    else {
        vec4 outlineColor;
        if (color == 2.0) { outlineColor = vec4(1.0, 0.0, 0.0, 1.0); }      // red
        else if (color == 3.0) { outlineColor = vec4(0.0, 1.0, 0.0, 1.0); } // green
        else if (color == 4.0) { outlineColor = vec4(0.0, 0.0, 1.0, 1.0); } // blue
        else if (color == 5.0) { outlineColor = vec4(1.0, 1.0, 1.0, 1.0); } // white
        else if (color == 6.0) { outlineColor = vec4(0.0, 0.0, 0.0, 1.0); } // black
        
        if (sourceColor.r < edgeColor.r && sourceColor.g < edgeColor.g && sourceColor.b < edgeColor.b) {
            fragColor = outlineColor;
        } else {
            fragColor = max(sourceColor, edgeColor);
            fragColor.r = max(sourceColor.r, edgeColor.r);
        }
        
    }
    
    
    targetTexture.write(fragColor, gridPosition);
}
