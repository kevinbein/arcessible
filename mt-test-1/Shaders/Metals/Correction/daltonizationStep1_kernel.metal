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
kernel void daltonizationStep1_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::sample> noiseTexture [[texture(2)]],
    texture2d<float, access::write> temporaryTexture1 [[texture(3)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    vec4 fragColor = sourceTexture.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    vec2 position = vec2(
                         gridPosition.x % sourceTexture.get_width(),
                         floor(float(gridPosition.y / sourceTexture.get_height()))
                         );
    vec4 t = vec4(noiseTexture.sample(s, position)); // texture2DRect(noisetex, gl_TexCoord[0].st);
    vec4 o = vec4(sourceTexture.sample(s, position)); // texture2DRect(labtex, gl_TexCoord[0].st); // .st === .xy
    vec4 n = vec4(sourceTexture.sample(s, t.xy)); // texture2DRect(labtex, t.xy);
    
    float Da = o.y - n.y;
    float Db = o.z - n.z;
    float DL = o.x - n.x;
    float Da2 = pow(Da, 2.0);
    float Db2 = pow(Db, 2.0);
    float DL2 = pow(DL, 2.0);
    float DLab = sqrt(DL2 + Da2 + Db2);
    float DLb = sqrt(DL2 + Db2);
    
    float factor = 1.0;
    if (DLab != 0.0) {
        factor = abs(DLb) / DLab;
    }
    float c = 1.0 - factor;
    
    float a = c * Da;
    float b = c * Db;
        
    col = vec3(a * a, a * b, b * b);

    // ========= Custom code END =========
    
    // Output to screen
    fragColor = vec4(vec3(col), 1.0);
    
    temporaryTexture1.write(fragColor, gridPosition);
    //temporaryTexture1.write(vec4(1.0,.0,.0,.1), gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
