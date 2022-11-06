//
//  saturation.metal
//  mt-test-1
//
//  Created by Kevin Bein on 17.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "../Utils/types.h"
#include "../Utils/color.h"

kernel void hsbc_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &hue [[buffer(1)]],
    constant float &saturation [[buffer(2)]],
    constant float &brightness [[buffer(3)]],
    constant float &contrast [[buffer(4)]],
    constant float &correctGamma [[buffer(5)]]
) {
    
    // float4 pixelColor = tex2D(Texture1Sampler, uv);
    /*float4 pixelColor = sourceTexture.read(gridPosition);
    pixelColor.rgb /= pixelColor.a;
    // Apply saturation.
    pixelColor.rgb = ((pixelColor.rgb - 0.5f) * max(saturation, 0.0)) + 0.5f;
    // Apply brightness.
    //pixelColor.rgb += Brightness;
    // Return final pixel color.
    pixelColor.rgb *= pixelColor.a;
    targetTexture.write(vec4(vec3(pixelColor), 1.0), gridPosition);*/

    vec4 sourceColor = sourceTexture.read(gridPosition);
    
    vec4 rgba = sourceColor;
    if (correctGamma == 1.0) {
        rgba = gammaCorrection(sourceColor.rgb);
    }
    
    //vec4 rgba = float4(pow(sourceColor.rgb, float3(2,2,2)), sourceColor.a);

    float4 hsbc = vec4(hue, saturation, brightness, contrast);
    vec4 outputColor = applyHSBCffect(rgba, hsbc);
    targetTexture.write(outputColor, gridPosition);
    //targetTexture.write(sourceTexture.read(gridPosition), gridPosition);
    
    //vec3 hsv = rgb2hsv(sourceColor.bgr);
    //hsv.y = saturation;
    //vec3 rgb = hsv2rgb(hsv);
    //targetTexture.write(vec4(hsv, 1), gridPosition);
}
