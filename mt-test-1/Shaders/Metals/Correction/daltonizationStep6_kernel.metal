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

constant mat3 mXYZtoRGB = mat3(3.24070846, -0.96925735, 0.05563507,
                            -1.53725917, 1.87599516, -0.20399580,
                            -0.49857039, 0.04155555, 1.05706957);
// White reference
//constexpr float Xn = 0.412453 + 0.357580 + 0.180423;
//constexpr float Yn = 0.212671 + 0.715160 + 0.072169;
//constexpr float Zn = 0.019334 + 0.119193 + 0.950227;

//float LabFi(const float x)
//{
//    return (x >= 0.206893 ?(x*x*x):((x-16.0/116.0)/7.787));
//}

constant mat3 rotProt_x = { {1., -0., 0.}, {0., 0.98000014, 0.19899679}, {-0., -0.19899679, 0.98000014} };
constant mat3 rotProt_y = { { 0.98000014, -0.,-0.19899679}, { 0., 1., -0.}, { 0.19899679, 0., 0.98000014} };
constant mat3 rotProt_z = { { 0.98000014, 0.19899679, 0. }, { -0.19899679, 0.98000014, -0. }, {-0. ,0. ,1. } };
// -8.10959f
constant mat3 rotDeut_x = { {1., -0., 0.}, {0., 0.99000006, 0.14106694}, {-0., -0.14106694, 0.99000006} };
constant mat3 rotDeut_y = { { 0.99000006, -0., -0.14106694}, { 0., 1., -0.}, { 0.14106694, 0., 0.99000006} };
constant mat3 rotDeut_z = {{ 0.99000006, 0.14106694, 0. }, { -0.14106694, 0.99000006, -0. }, { -0., 0., 1. } };
// +46.37f
constant mat3 rotTrit_x = { {1., 0., 0.}, {0., 0.68999862, -0.72381068}, {0., 0.72381068, 0.68999862} };
constant mat3 rotTrit_y = { { 0.68999862, 0., 0.72381068}, { 0., 1., 0.,}, { -0.72381068, 0., 0.68999862 } };
constant mat3 rotTrit_z = { { 0.68999862, -0.72381068, 0. },{ 0.72381068, 0.68999862, 0. }, { 0., 0., 1.} };


float invF(const float p)
{
    float r = p*p*p;
    if (r < 0.008856)
        return (p-4.0/29.0)*(108.0/841.0);
    else
        return r;
}

// Convert input Lab to XYZ color space
vec3 LabToXYZ(const vec3 vector)
{
    float Y = (vector.x + 16.0)/116.0;
    float X = Y + vector.y/500.0;
    float Z = Y - vector.z/200.0;
    X = 0.950456 * invF(X);
    Y = 1.0 * invF(Y);
    Z = 1.088754 * invF(Z);
//    float L = vector.x, a = vector.y, b = vector.z;
//    float cY = (L + 16.0) / 116.0, Y = Yn * LabFi(cY), pY = pow(Y / Yn, 1.0 / 3.0);
//    float cX = a / 500.0 + pY, X = Xn * cX * cX * cX;
//    float cZ = pY - b / 200.0, Z = Zn * cZ * cZ * cZ;
    return vec3(X, Y, Z);
}

float IgammaCorrection(const float value)
{
    float ret;
    if (value <= 0.018) {
        ret = value*4.5138;
    } else {
        ret = 1.099 * pow(value,0.45) - 0.099;
    }
    return ret;
}

vec3 IRGBGammaCorrection(const vec3 rgbcol)
{
    return vec3(IgammaCorrection(rgbcol.x),IgammaCorrection(rgbcol.y),IgammaCorrection(rgbcol.z));
}


// Default kernel method
kernel void daltonizationStep6_kernel(
    texture2d<float, access::sample> sourceTexture [[texture(0)]],
    texture2d<float, access::write> targetTexture [[texture(1)]],
    uint2 gridPosition [[thread_position_in_grid]],
    constant float &typeF [[buffer(1)]],
    texture2d<float, access::sample> Lab [[texture(2)]]
) {
    uint type = uint(typeF); // 0..2
    
    // Metal to Shadertoy naming conversion
    //vec4 fragColor = AtA.read(gridPosition);
    vec3 col;
    
    // ========= Custom code START =========
    
    mat3 rotMat = type == 0 ? rotProt_y : (type == 1 ? rotProt_y : rotTrit_y);
    
    // Convert Lab to RGB
    vec4 fragColor;
    fragColor.xyz = Lab.sample(s, vec2(gridPosition)).xyz; // texture2DRect(Lab, gl_TexCoord[0].xy).xyz;
    fragColor.xyz = rotMat * fragColor.xyz;
    fragColor.xyz = LabToXYZ(fragColor.xyz);
    fragColor.xyz = mXYZtoRGB * fragColor.xyz;
    fragColor.xyz = IRGBGammaCorrection(fragColor.xyz);
    fragColor.xyz = max(min(fragColor.xyz,vec3(1.0,1.0,1.0)),vec3(0.0,0.0,0.0));
    fragColor.w = 0.0;
    
    // ========= Custom code END =========
    
    // Output to screen
    //fragColor = vec4(vec3(col), 1.0);
    fragColor = Lab.sample(s, vec2(gridPosition));
    
    targetTexture.write(fragColor, gridPosition);
    //targetTexture.write(noiseTexture.read(gridPosition), gridPosition);
}
