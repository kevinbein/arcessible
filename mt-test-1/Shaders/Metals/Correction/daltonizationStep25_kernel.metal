//
//  daltonization.metal
//  mt-test-1
//
//  Created by Kevin Bein on 04.10.22.
//

#include <metal_stdlib>
using namespace metal;

// Metal Shadertoy types
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat3 float3x3

constexpr sampler s = sampler(coord::normalized, address::clamp_to_edge, filter::linear);

// Default kernel method
kernel void daltonizationStep25_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::sample> AtA [[texture(2)]],
    texture2d<float, access::write> temporaryTexture3 [[texture(3)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    //vec4 fragColor = AtA.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    vec2 dimB = vec2(gridPosition);
    vec2 p1 = (vec2(dimB) - 0.5) * 2.0 + 0.5;
    
    vec4 fragColor = AtA.sample(s, p1); // gl_FragColor = texture2DRect( AtA, p1);
    
    vec4 mAtA = AtA.sample(s, dimB);
    
    // Compute AutoVector of matrix [aa ab; ba bb]
    // Bhaskara
    float a = 1.0;
    float b = -(mAtA.x+mAtA.z);
    float c = mAtA.x*mAtA.z-mAtA.y*mAtA.y;
    float D = pow(b,2.0)-4.0*a*c;
    float x1 = ( -b + sqrt(D) )/(2.0*a);
    float x2 = ( -b - sqrt(D) )/(2.0*a);

    float x = (abs(x1)>abs(x2))?x1:x2;

    // we fix b* way
    fragColor.x = (x-mAtA.z)/mAtA.y;
    fragColor.y = 1.0;
    
    //col = fragColor;
    
    // ========= Custom code END =========
    
    // Output to screen
    //fragColor = vec4(vec3(col), 1.0);
    
    temporaryTexture3.write(fragColor, gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
