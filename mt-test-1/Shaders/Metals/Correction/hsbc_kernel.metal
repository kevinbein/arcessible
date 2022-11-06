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

// Credits: https://forum.unity.com/threads/hue-saturation-brightness-contrast-shader.260649/

constant float PI = 3.14159265359;

float radians(float in) {
    return in * (PI / 180);
}

inline float3 applyHue(float3 aColor, float aHue)
{
    float angle = radians(aHue);
    float3 k = float3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(angle);
    //Rodrigues' rotation formula
    return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
}
 
// Default values for no changes at all:
// hue        = 0.0
// brightness = 0.5
// contrast   = 0.5
// saturation = 0.5
inline float4 applyHSBEffect(float4 startColor, float4 hsbc)
{
    float hue = 360 * hsbc.r;
    float brightness = hsbc.g * 2 - 1;
    float contrast = hsbc.b * 2;
    float saturation = hsbc.a * 2;
 
    float4 outputColor = startColor;
    outputColor.rgb = applyHue(outputColor.rgb, hue);
    outputColor.rgb = (outputColor.rgb - 0.5f) * (contrast) + 0.5f;
    outputColor.rgb = outputColor.rgb + brightness;
    float3 intensity = dot(outputColor.rgb, float3(0.299,0.587,0.114));
    outputColor.rgb = mix(intensity, outputColor.rgb, saturation);
 
    return outputColor;
}

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
    vec4 outputColor = applyHSBEffect(rgba, hsbc);
    targetTexture.write(outputColor, gridPosition);
    //targetTexture.write(sourceTexture.read(gridPosition), gridPosition);
    
    //vec3 hsv = rgb2hsv(sourceColor.bgr);
    //hsv.y = saturation;
    //vec3 rgb = hsv2rgb(hsv);
    //targetTexture.write(vec4(hsv, 1), gridPosition);
}
