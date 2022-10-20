//
//  contrast.metal
//  mt-test-1
//
//  Created by Kevin Bein on 17.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/colorConversion.h"

kernel void contrast_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &saturation [[buffer(1)]]
) {
    
    // float4 pixelColor = tex2D(Texture1Sampler, uv);
    /*float4 pixelColor = sourceTexture.read(gridPosition);
    pixelColor.rgb /= pixelColor.a;
    // Apply contrast.
    pixelColor.rgb = ((pixelColor.rgb - 0.5f) * max(saturation, 0.0)) + 0.5f;
    // Apply brightness.
    //pixelColor.rgb += Brightness;
    // Return final pixel color.
    pixelColor.rgb *= pixelColor.a;
    targetTexture.write(vec4(vec3(pixelColor), 1.0), gridPosition);*/
    
    
    float4 sourceColor = sourceTexture.read(gridPosition);
    vec3 hsv = rgb2hsv(sourceColor.rgb);
    hsv.y = saturation;
    vec3 rgb = hsv2rgb(hsv);
    targetTexture.write(vec4(hsv, 1), gridPosition);
}
