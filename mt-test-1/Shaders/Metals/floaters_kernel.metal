//
//  floaters.metal
//  mt-test-1
//
//  Created by Kevin Bein on 17.07.22.
//

#include <metal_stdlib>
using namespace metal;

float  noise(float param)   { return fract(sin(param) * 43758.937545312382); }

float2 noise2(float2 param) { return fract(sin(param) * 43758.937545312382); }

float3 circle(float2 uv, float seed, float iTime)
{
    float rnd = noise(seed);
    float period = 2.0 + 2.0*rnd;
    float age = fmod(iTime + seed, period);
    float nAge = age / period;
    float t = floor(iTime - age + 0.5) + seed;
    
    float2 n = noise2(float2(t, t + 42.34231));
    
    float grad = length((uv*2.0-1.0) - n);
    
    nAge = sqrt(nAge);
    
    //shape
    float r = 1.0;
    r *= smoothstep(0.3*nAge, 0.8*nAge, grad);
    r *= 1.0-smoothstep(0.8*nAge, 1.0*nAge, grad);
    
    //opacity
    r *= sin(nAge*3.1415)+.5;
    //r *= 1.0-nAge*nAge;
    
    float3 clr = float3(1.0, 0.5, 0.3);
    
    float3 clrBase = float3(1.0, 0.8, 0.3);
    float3 clrOpposite = float3(1.0) - clrBase;
    
    return float3(r);// * mix(clrBase, clrOpposite, 0.5 + sign(n.x-0.5) * (0.5+0.5*n.y) );
    
    return float3(r);// * clr * (0.3+0.7*frac(100.0*float3(n.x, n.y, 1.0-n.x*n.y)));
}

kernel void floaters_kernel(
    texture2d<float, access::read> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &time [[buffer(0)]]
) {
    float4 sourceColor = sourceTexture.read(gridPosition);
    float2 resolution = float2(sourceTexture.get_width(), sourceTexture.get_height());
    float2 uv = float2(gridPosition) / resolution;
    uv.x *= resolution.x / resolution.y; //fix aspect ratio
    
    uv += float2(.5,.1);
    
    float iTime = time;
    
    float3 c = float3(0.0);
    
    c.rgb  = circle(uv, 0.321517, iTime);
    c.rgb += circle(uv, 1.454352, iTime);
    c.rgb += circle(uv, 2.332126, iTime);
    c.rgb += circle(uv, 3.285356, iTime);
    c.rgb += circle(uv, 4.194621, iTime);
    
    //tone mapping
    float lum = dot(c.rgb, float3(0.3333));
    if(c.r>1.0) c.r = 2.0 - exp(-c.r + 1.0);
    if(c.g>1.0) c.g = 2.0 - exp(-c.g + 1.0);
    if(c.b>1.0) c.b = 2.0 - exp(-c.b + 1.0);
    
    c = c * 0.7;
    
    float4 outColor = min(sourceColor, float4(float3(c), 1.0));
    //outColor = float4(c, 1.0);
    
    targetTexture.write(outColor, gridPosition);
}

