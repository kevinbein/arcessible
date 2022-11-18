//
//  colorConversion_kernel.metal
//  mt-test-1
//
//  Created by Kevin Bein on 18.10.22.
//

#include <metal_stdlib>
using namespace metal;

#include "color.h"

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html
vec4 gammaCorrection(vec3 c) {
    return vec4(mix(c.rgb, pow(c.rgb * 0.9479 + 0.05213, 2.4), step(0.04045, c.rgb)), 1.0);
}

vec4 getJetColorsFromNormalizedVal(half val) {
    vec4 res ;
    if(val <= 0.01h)
        return vec4();
    res.r = 1.5h - fabs(4.0h * val - 3.0h);
    res.g = 1.5h - fabs(4.0h * val - 2.0h);
    res.b = 1.5h - fabs(4.0h * val - 1.0h);
    res.a = 1.0h;
    res = clamp(res,0.0h,1.0h);
    return res;
}

// Credits: https://forum.unity.com/threads/hue-saturation-brightness-contrast-shader.260649/

constant float PI = 3.14159265359;

float radians(float in) {
    return in * (PI / 180);
}

float3 applyHue(float3 aColor, float aHue) {
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
float4 applyHSBCffect(float4 startColor, float4 hsbc) {
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
