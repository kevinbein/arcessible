//
//  gammaCorrection_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 05.11.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

kernel void gammaCorrection_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]]
) {
    vec4 sourceColor = sourceTexture.read(gridPosition);
    
    vec4 rgba = gammaCorrection(sourceColor.rgb);
    
    targetTexture.write(rgba, gridPosition);
}
