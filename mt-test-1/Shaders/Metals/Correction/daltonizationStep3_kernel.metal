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
kernel void daltonizationStep3_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::write> AtA [[texture(2)]],
    texture2d<float, access::sample> Eab [[texture(3)]],
    texture2d<float, access::sample> Lab [[texture(4)]]
    //texture2d<float, access::sample> temporaryTexture1 [[texture(3)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    //vec4 fragColor = AtA.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    vec2 o = vec2(0.5,0.5);
    vec4 EaEb = Eab.sample(s, o);
    vec4 fragColor = Lab.sample(s, vec2(gridPosition)); // gl_FragColor = texture2DRect( Lab, gl_TexCoord[0].st);
    fragColor.x = fragColor.y * EaEb.x + fragColor.z * EaEb.y;
    fragColor.y = sqrt(pow(fragColor.y,2.0)+pow(fragColor.z,2.0));
    
    //col = fragColor;
    
    // ========= Custom code END =========
    
    // Output to screen
    //fragColor = vec4(vec3(col), 1.0);
    
    AtA.write(fragColor, gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
